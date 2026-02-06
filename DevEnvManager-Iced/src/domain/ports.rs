use std::time::Duration;

use tokio::process::Command;
use tokio::time::timeout;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PortInfo {
    pub port: u16,
    pub pid: u32,
    pub process: String,
    pub address: String,
}

pub async fn list_ports() -> Vec<PortInfo> {
    let output = match timeout(
        Duration::from_secs(30),
        Command::new("lsof")
            .args(["-iTCP", "-sTCP:LISTEN", "-P", "-n"])
            .output(),
    )
    .await
    {
        Ok(Ok(output)) => output,
        Ok(Err(error)) => {
            eprintln!("Failed to run lsof: {error}");
            return Vec::new();
        }
        Err(_) => {
            eprintln!("lsof timed out after 30s");
            return Vec::new();
        }
    };

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("lsof failed: {stderr}");
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    parse_ports_output(&stdout)
}

pub fn parse_ports_output(output: &str) -> Vec<PortInfo> {
    let mut ports = Vec::new();

    for (index, line) in output.lines().enumerate() {
        if index == 0 {
            continue;
        }

        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() < 9 {
            continue;
        }

        let process = parts[0].to_string();
        let pid = parts[1].parse::<u32>().unwrap_or(0);

        let address_token = parts.iter().find(|token| token.contains(':'));
        let address_token = match address_token {
            Some(token) => token.trim_end_matches("(LISTEN)"),
            None => continue,
        };

        let address_token = address_token.trim();
        let (address, port) = match address_token.rsplit_once(':') {
            Some((address, port)) => (address.to_string(), port),
            None => continue,
        };

        let port = match port.parse::<u16>() {
            Ok(port) => port,
            Err(_) => continue,
        };

        ports.push(PortInfo {
            port,
            pid,
            process,
            address,
        });
    }

    ports
}
