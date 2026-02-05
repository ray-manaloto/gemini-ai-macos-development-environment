use tokio::process::Command;

use crate::models::{Container, ContainerState};

pub async fn list_containers() -> Vec<Container> {
    let output = Command::new("orb").args(["list"]).output().await;

    let output = match output {
        Ok(output) => output,
        Err(error) => {
            eprintln!("Failed to run orb list: {error}");
            return Vec::new();
        }
    };

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("orb list failed: {stderr}");
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    parse_containers_output(&stdout)
}

pub async fn start_container(name: String) {
    if let Err(error) = run_orb(["start", &name]).await {
        eprintln!("Failed to start {name}: {error}");
    }
}

pub async fn stop_container(name: String) {
    if let Err(error) = run_orb(["stop", &name]).await {
        eprintln!("Failed to stop {name}: {error}");
    }
}

async fn run_orb<const N: usize>(args: [&str; N]) -> Result<(), String> {
    let output = Command::new("orb")
        .args(args)
        .output()
        .await
        .map_err(|error| error.to_string())?;

    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(stderr.to_string())
    }
}

pub fn parse_containers_output(output: &str) -> Vec<Container> {
    let mut containers = Vec::new();

    for (index, line) in output.lines().enumerate() {
        if index == 0 && line.to_lowercase().contains("name") {
            continue;
        }

        if line.trim().is_empty() {
            continue;
        }

        let mut parts = line.split_whitespace();
        let name = match parts.next() {
            Some(name) => name.to_string(),
            None => continue,
        };

        let status_raw = parts.next().unwrap_or("unknown");
        let status = status_raw.to_string();
        let image = parts.next().map(|value| value.to_string());

        let state = match status_raw.to_lowercase().as_str() {
            "running" => ContainerState::Running,
            "stopped" => ContainerState::Stopped,
            _ => ContainerState::Unknown,
        };

        containers.push(Container {
            name,
            image,
            state,
            status: Some(status),
        });
    }

    containers
}
