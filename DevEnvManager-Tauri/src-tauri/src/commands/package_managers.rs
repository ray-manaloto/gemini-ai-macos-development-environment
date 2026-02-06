use serde::Serialize;

use crate::commands::run_command;

#[derive(Debug, Serialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum PackageManagerStatus {
    Healthy,
    Warning,
    Error,
    Unknown,
}

#[derive(Debug, Serialize)]
pub struct PackageManager {
    name: String,
    display_name: String,
    emoji: String,
    version: String,
    status: PackageManagerStatus,
    message: Option<String>,
}

async fn get_version(command: &str, args: &[&str]) -> Result<String, String> {
    let output = run_command(command, args).await?;
    // Extract version from output (usually first line or contains version number)
    let version = output
        .lines()
        .next()
        .unwrap_or("unknown")
        .trim()
        .to_string();
    Ok(version)
}

async fn check_mise_health() -> PackageManagerStatus {
    match run_command("mise", &["doctor"]).await {
        Ok(output) => {
            let lower = output.to_lowercase();
            if lower.contains("error") || lower.contains("failed") {
                PackageManagerStatus::Error
            } else if lower.contains("warn") {
                PackageManagerStatus::Warning
            } else {
                PackageManagerStatus::Healthy
            }
        }
        Err(_) => PackageManagerStatus::Error,
    }
}

#[tauri::command]
pub async fn get_package_managers_status() -> Result<Vec<PackageManager>, String> {
    let mut managers = Vec::new();

    // Mise
    let mise_version = get_version("mise", &["--version"])
        .await
        .unwrap_or_else(|_| "not installed".to_string());
    let mise_status = if mise_version.contains("not installed") {
        PackageManagerStatus::Error
    } else {
        check_mise_health().await
    };
    managers.push(PackageManager {
        name: "mise".to_string(),
        display_name: "Mise".to_string(),
        emoji: "🔧".to_string(),
        version: mise_version,
        status: mise_status,
        message: None,
    });

    // Bun
    let bun_version = get_version("bun", &["--version"])
        .await
        .unwrap_or_else(|_| "not installed".to_string());
    let bun_status = if bun_version.contains("not installed") {
        PackageManagerStatus::Error
    } else {
        PackageManagerStatus::Healthy
    };
    managers.push(PackageManager {
        name: "bun".to_string(),
        display_name: "Bun".to_string(),
        emoji: "🥟".to_string(),
        version: bun_version,
        status: bun_status,
        message: None,
    });

    // Uv
    let uv_version = get_version("uv", &["--version"])
        .await
        .unwrap_or_else(|_| "not installed".to_string());
    let uv_status = if uv_version.contains("not installed") {
        PackageManagerStatus::Error
    } else {
        PackageManagerStatus::Healthy
    };
    managers.push(PackageManager {
        name: "uv".to_string(),
        display_name: "Uv".to_string(),
        emoji: "🐍".to_string(),
        version: uv_version,
        status: uv_status,
        message: None,
    });

    // Pixi
    let pixi_version = get_version("pixi", &["--version"])
        .await
        .unwrap_or_else(|_| "not installed".to_string());
    let pixi_status = if pixi_version.contains("not installed") {
        PackageManagerStatus::Error
    } else {
        PackageManagerStatus::Healthy
    };
    managers.push(PackageManager {
        name: "pixi".to_string(),
        display_name: "Pixi".to_string(),
        emoji: "🦊".to_string(),
        version: pixi_version,
        status: pixi_status,
        message: None,
    });

    Ok(managers)
}

#[tauri::command]
pub async fn update_package_manager(name: String) -> Result<String, String> {
    match name.as_str() {
        "bun" => run_command("mise", &["use", "-g", "bun@latest"]).await,
        "uv" => run_command("mise", &["use", "-g", "uv@latest"]).await,
        "pixi" => run_command("mise", &["use", "-g", "pixi@latest"]).await,
        "mise" => run_command("mise", &["self-update"]).await,
        _ => Err(format!("Unknown package manager: {name}")),
    }
}
