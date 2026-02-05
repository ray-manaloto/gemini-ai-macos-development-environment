use tokio::process::Command;

use crate::models::{Service, ServiceStatus};

pub async fn list_services() -> Vec<Service> {
    let output = Command::new("brew")
        .args(["services", "list"])
        .output()
        .await;

    let output = match output {
        Ok(output) => output,
        Err(error) => {
            eprintln!("Failed to run brew services list: {error}");
            return Vec::new();
        }
    };

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("brew services list failed: {stderr}");
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    parse_services_output(&stdout)
}

pub async fn start_service(name: String) {
    if let Err(error) = run_brew(["services", "start", &name]).await {
        eprintln!("Failed to start {name}: {error}");
    }
}

pub async fn stop_service(name: String) {
    if let Err(error) = run_brew(["services", "stop", &name]).await {
        eprintln!("Failed to stop {name}: {error}");
    }
}

pub async fn restart_service(name: String) {
    if let Err(error) = run_brew(["services", "restart", &name]).await {
        eprintln!("Failed to restart {name}: {error}");
    }
}

async fn run_brew<const N: usize>(args: [&str; N]) -> Result<(), String> {
    let output = Command::new("brew")
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

pub fn parse_services_output(output: &str) -> Vec<Service> {
    let mut services = Vec::new();

    for (index, line) in output.lines().enumerate() {
        if index == 0 {
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

        let status_token = match parts.next() {
            Some(status) => status,
            None => continue,
        };

        let mut exit_code: Option<i32> = None;
        let status = match status_token {
            "started" => ServiceStatus::Started,
            "stopped" => ServiceStatus::Stopped,
            "none" => ServiceStatus::None,
            "error" => {
                exit_code = parts.next().and_then(|value| value.parse::<i32>().ok());
                ServiceStatus::Error
            }
            _ => ServiceStatus::Unknown,
        };

        let user = parts.next().map(|value| value.to_string());
        let file = parts.collect::<Vec<_>>().join(" ");
        let file = if file.is_empty() { None } else { Some(file) };

        services.push(Service {
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
