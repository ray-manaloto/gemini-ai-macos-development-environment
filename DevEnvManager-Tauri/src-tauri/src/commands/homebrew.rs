use crate::commands::run_command;
use crate::models::{BrewService, BrewServiceStatus};

pub fn parse_brew_services(output: &str) -> Vec<BrewService> {
    let mut services = Vec::new();

    for (index, line) in output.lines().enumerate() {
        if index == 0 {
            continue;
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let parts: Vec<&str> = trimmed.split_whitespace().collect();
        if parts.len() < 2 {
            continue;
        }

        let name = parts[0].to_string();
        let status_str = parts[1];
        let status = BrewServiceStatus::from_raw(status_str);

        // Only parse exit_code from the token after "error" status
        let exit_code = if status_str == "error" {
            parts.get(2).and_then(|value| value.parse::<i32>().ok())
        } else {
            None
        };

        let user = if status_str == "error" {
            parts.get(3).map(|value| value.to_string())
        } else {
            parts.get(2).map(|value| value.to_string())
        };

        let file = if status_str == "error" {
            parts.get(4).map(|value| value.to_string())
        } else {
            parts.get(3).map(|value| value.to_string())
        };

        services.push(BrewService {
            name,
            status,
            user,
            file,
            exit_code,
            port: None,
            pid: None,
        });
    }

    services
}

#[tauri::command]
pub async fn list_brew_services() -> Result<Vec<BrewService>, String> {
    let output = run_command("brew", &["services", "list"]).await?;
    Ok(parse_brew_services(&output))
}

#[tauri::command]
pub async fn start_service(name: String) -> Result<String, String> {
    run_command("brew", &["services", "start", &name]).await
}

#[tauri::command]
pub async fn stop_service(name: String) -> Result<String, String> {
    run_command("brew", &["services", "stop", &name]).await
}

#[tauri::command]
pub async fn restart_service(name: String) -> Result<String, String> {
    run_command("brew", &["services", "restart", &name]).await
}
