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
        let status = BrewServiceStatus::from_raw(parts[1]);
        let user = parts.get(2).map(|value| value.to_string());
        let file = parts.get(3).map(|value| value.to_string());

        let exit_code = parts
            .iter()
            .rev()
            .find_map(|value| value.parse::<i32>().ok());

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
