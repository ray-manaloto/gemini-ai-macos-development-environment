use crate::commands::run_command;
use crate::models::{Container, ContainerState};

pub fn parse_orb_list(output: &str) -> Vec<Container> {
    let mut containers = Vec::new();
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
        let state = ContainerState::from_raw(parts[1]);
        containers.push(Container {
            id: name.clone(),
            name,
            image: String::new(),
            state,
            status: parts.get(2).map(|value| value.to_string()).unwrap_or_default(),
            ports: Vec::new(),
        });
    }
    containers
}

#[tauri::command]
pub async fn list_containers() -> Result<Vec<Container>, String> {
    let output = run_command("orb", &["list"]).await?;
    Ok(parse_orb_list(&output))
}

#[tauri::command]
pub async fn start_container(name: String) -> Result<String, String> {
    run_command("orb", &["start", &name]).await
}

#[tauri::command]
pub async fn stop_container(name: String) -> Result<String, String> {
    run_command("orb", &["stop", &name]).await
}

#[tauri::command]
pub async fn restart_container(name: String) -> Result<String, String> {
    // OrbStack doesn't have native restart, so stop then start
    run_command("orb", &["stop", &name]).await?;
    run_command("orb", &["start", &name]).await
}

#[tauri::command]
pub async fn shell_container(name: String) -> Result<String, String> {
    run_command("open", &["-a", "Terminal", &format!("orb shell {name}")]).await
}

#[tauri::command]
pub async fn logs_container(name: String) -> Result<String, String> {
    run_command("orb", &["logs", "--tail", "100", &name]).await
}
