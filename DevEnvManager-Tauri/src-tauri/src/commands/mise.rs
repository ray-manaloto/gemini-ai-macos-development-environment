use serde::Deserialize;
use tauri::Emitter;

use crate::commands::run_command;
use crate::models::{MiseTool, MiseToolSource};

#[derive(Debug, Deserialize)]
struct MiseToolEntry {
    version: String,
    #[serde(rename = "requested_version")]
    requested_version: Option<String>,
    #[serde(rename = "install_path")]
    install_path: Option<String>,
    source: Option<MiseToolSourceEntry>,
    installed: bool,
}

#[derive(Debug, Deserialize)]
struct MiseToolSourceEntry {
    #[serde(rename = "type")]
    r#type: Option<String>,
    path: Option<String>,
}

pub fn parse_mise_tools(json: &str) -> Result<Vec<MiseTool>, String> {
    let tools_map: std::collections::BTreeMap<String, Vec<MiseToolEntry>> =
        serde_json::from_str(json)
            .map_err(|error| format!("Failed to parse mise output: {error}"))?;

    let mut tools = Vec::new();
    for (name, entries) in tools_map {
        for entry in entries {
            tools.push(MiseTool {
                name: name.clone(),
                version: entry.version,
                requested_version: entry.requested_version,
                install_path: entry.install_path,
                source: entry.source.map(|source| MiseToolSource {
                    r#type: source.r#type,
                    path: source.path,
                }),
                installed: entry.installed,
            });
        }
    }

    Ok(tools)
}

/// Emit a progress event to the frontend via the Tauri event system.
fn emit_progress(
    window: &tauri::Window,
    operation: &str,
    status: &str,
    percent: u8,
    message: &str,
) {
    window
        .emit(
            "operation-progress",
            serde_json::json!({
                "operation": operation,
                "status": status,
                "percent": percent,
                "message": message,
            }),
        )
        .ok();
}

#[tauri::command]
pub async fn list_mise_tools() -> Result<Vec<MiseTool>, String> {
    let output = run_command("mise", &["ls", "--json"]).await?;
    parse_mise_tools(&output)
}

#[tauri::command]
pub async fn install_tool(name: String) -> Result<String, String> {
    let target = format!("{name}@latest");
    run_command("mise", &["use", "-g", &target]).await
}

#[tauri::command]
pub async fn update_tool(name: String) -> Result<String, String> {
    let target = format!("{name}@latest");
    run_command("mise", &["use", "-g", &target]).await
}

#[tauri::command]
pub async fn mise_doctor() -> Result<String, String> {
    run_command("mise", &["doctor"]).await
}

#[tauri::command]
pub async fn run_mise_validate() -> Result<String, String> {
    run_command("mise", &["run", "validate"]).await
}

#[tauri::command]
pub async fn run_mise_doctor() -> Result<String, String> {
    run_command("mise", &["run", "tools:doctor"]).await
}

#[tauri::command]
pub async fn run_mise_update_all(window: tauri::Window) -> Result<String, String> {
    emit_progress(&window, "update_all", "started", 0, "Starting update...");

    emit_progress(
        &window,
        "update_all",
        "progress",
        20,
        "Checking for tool updates...",
    );

    let result = run_command("mise", &["run", "tools:update"]).await;

    match &result {
        Ok(output) => {
            emit_progress(
                &window,
                "update_all",
                "completed",
                100,
                "All tools updated",
            );
            Ok(output.clone())
        }
        Err(error) => {
            emit_progress(
                &window,
                "update_all",
                "failed",
                0,
                &format!("Update failed: {error}"),
            );
            Err(error.clone())
        }
    }
}

#[tauri::command]
pub async fn run_mise_dashboard() -> Result<String, String> {
    run_command("mise", &["run", "dashboard"]).await
}
