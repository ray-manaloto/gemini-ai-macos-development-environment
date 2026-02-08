//! Telemetry module for DevEnvManager
//!
//! Provides local-first telemetry collection with optional remote sync.
//! Events are stored in ~/.config/dev-env/telemetry/events.jsonl

use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use uuid::Uuid;

/// Telemetry event structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryEvent {
    pub id: String,
    pub timestamp: String,
    pub source: String,
    pub machine_id: String,
    pub category: String,
    pub name: String,
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mise_version: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payload: Option<serde_json::Value>,
}

/// Telemetry configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryConfig {
    pub enabled: bool,
    pub remote_sync: bool,
    pub remote_endpoint: Option<String>,
    pub retention_days: u32,
    pub max_storage_mb: u32,
    pub machine_id: String,
}

impl Default for TelemetryConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            remote_sync: false,
            remote_endpoint: None,
            retention_days: 30,
            max_storage_mb: 100,
            machine_id: generate_machine_id(),
        }
    }
}

/// Generate a hashed machine ID from hostname
fn generate_machine_id() -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    let hostname = hostname::get()
        .map(|h| h.to_string_lossy().to_string())
        .unwrap_or_else(|_| "unknown".to_string());

    let mut hasher = DefaultHasher::new();
    hostname.hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

/// Get mise version
fn get_mise_version() -> Option<String> {
    std::process::Command::new("mise")
        .arg("--version")
        .output()
        .ok()
        .and_then(|output| {
            String::from_utf8(output.stdout)
                .ok()
                .map(|s| s.lines().next().unwrap_or("").trim().to_string())
        })
}

/// Telemetry manager for emitting and storing events
pub struct TelemetryManager {
    config: TelemetryConfig,
    base_path: PathBuf,
}

impl TelemetryManager {
    /// Create a new telemetry manager
    pub fn new() -> Self {
        let base_path = dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("dev-env")
            .join("telemetry");

        // Ensure directory exists
        fs::create_dir_all(&base_path).ok();

        let config = Self::load_config(&base_path);

        Self { config, base_path }
    }

    /// Load config from disk or create default
    fn load_config(base_path: &PathBuf) -> TelemetryConfig {
        let config_path = base_path.join("config.json");

        if config_path.exists() {
            fs::read_to_string(&config_path)
                .ok()
                .and_then(|content| serde_json::from_str(&content).ok())
                .unwrap_or_default()
        } else {
            let config = TelemetryConfig::default();
            // Save default config
            if let Ok(json) = serde_json::to_string_pretty(&config) {
                fs::write(&config_path, json).ok();
            }
            config
        }
    }

    /// Emit a telemetry event
    pub fn emit(&self, event: TelemetryEvent) -> Result<(), String> {
        if !self.config.enabled {
            return Ok(());
        }

        let events_path = self.base_path.join("events.jsonl");

        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&events_path)
            .map_err(|e| e.to_string())?;

        let json = serde_json::to_string(&event).map_err(|e| e.to_string())?;
        writeln!(file, "{}", json).map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Emit an operation event (convenience method)
    pub fn emit_operation(
        &self,
        name: &str,
        status: &str,
        payload: Option<serde_json::Value>,
    ) -> Result<(), String> {
        let event = TelemetryEvent {
            id: Uuid::new_v4().to_string(),
            timestamp: Utc::now().to_rfc3339(),
            source: "tauri".to_string(),
            machine_id: self.config.machine_id.clone(),
            category: "operation".to_string(),
            name: name.to_string(),
            status: status.to_string(),
            duration_ms: None,
            mise_version: get_mise_version(),
            payload,
        };
        self.emit(event)
    }

    /// Emit an error event
    pub fn emit_error(&self, name: &str, error_message: &str) -> Result<(), String> {
        self.emit_operation(
            name,
            "failed",
            Some(serde_json::json!({ "error": error_message })),
        )
    }

    /// Get the events file path
    pub fn events_path(&self) -> PathBuf {
        self.base_path.join("events.jsonl")
    }

    /// Check if telemetry is enabled
    pub fn is_enabled(&self) -> bool {
        self.config.enabled
    }
}

impl Default for TelemetryManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Global telemetry instance (lazy static)
use std::sync::OnceLock;
static TELEMETRY: OnceLock<TelemetryManager> = OnceLock::new();

/// Get the global telemetry manager
pub fn telemetry() -> &'static TelemetryManager {
    TELEMETRY.get_or_init(TelemetryManager::new)
}

/// Convenience macro for emitting telemetry
#[macro_export]
macro_rules! emit_telemetry {
    ($name:expr, $status:expr) => {
        $crate::telemetry::telemetry().emit_operation($name, $status, None).ok()
    };
    ($name:expr, $status:expr, $payload:expr) => {
        $crate::telemetry::telemetry().emit_operation($name, $status, Some($payload)).ok()
    };
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_generate_machine_id() {
        let id = generate_machine_id();
        assert_eq!(id.len(), 16);
    }

    #[test]
    fn test_telemetry_config_default() {
        let config = TelemetryConfig::default();
        assert!(config.enabled);
        assert!(!config.remote_sync);
        assert_eq!(config.retention_days, 30);
    }

    #[test]
    fn test_emit_event() {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path().to_path_buf();
        fs::create_dir_all(&base_path).unwrap();

        let config = TelemetryConfig::default();
        let manager = TelemetryManager {
            config,
            base_path: base_path.clone(),
        };

        let event = TelemetryEvent {
            id: "test-id".to_string(),
            timestamp: "2026-02-07T00:00:00Z".to_string(),
            source: "test".to_string(),
            machine_id: "test-machine".to_string(),
            category: "operation".to_string(),
            name: "test.event".to_string(),
            status: "completed".to_string(),
            duration_ms: Some(100),
            mise_version: None,
            payload: None,
        };

        manager.emit(event).unwrap();

        let events_content = fs::read_to_string(base_path.join("events.jsonl")).unwrap();
        assert!(events_content.contains("test-id"));
        assert!(events_content.contains("test.event"));
    }
}
