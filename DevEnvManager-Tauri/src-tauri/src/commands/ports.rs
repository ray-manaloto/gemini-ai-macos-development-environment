use crate::commands::run_command;
use crate::models::ActivePort;

pub fn parse_ports(output: &str) -> Vec<ActivePort> {
    let mut ports = Vec::new();
    for (index, line) in output.lines().enumerate() {
        if index == 0 {
            continue;
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let parts: Vec<&str> = trimmed.split_whitespace().collect();
        if parts.len() < 9 {
            continue;
        }

        let process = parts[0].to_string();
        let pid = parts[1].parse::<i32>().unwrap_or(-1);
        let protocol_index = parts.iter().position(|value| *value == "TCP" || *value == "UDP");
        let protocol_index = match protocol_index {
            Some(index) => index,
            None => continue,
        };

        let protocol = parts[protocol_index].to_string();
        let address = parts.get(protocol_index + 1).map(|value| value.to_string());
        let address = match address {
            Some(value) => value,
            None => continue,
        };

        let address_without_listen = address
            .split('(')
            .next()
            .unwrap_or("")
            .trim()
            .to_string();

        let parsed = parse_address_and_port(&address_without_listen);
        if let Some((local_address, port)) = parsed {
            ports.push(ActivePort {
                protocol,
                local_address,
                port,
                process,
                pid,
            });
        }
    }

    ports
}

fn parse_address_and_port(input: &str) -> Option<(String, u16)> {
    let trimmed = input.trim();
    let address_port = trimmed.strip_prefix("[").unwrap_or(trimmed);
    let address_port = address_port.strip_suffix("]").unwrap_or(address_port);
    let mut split = address_port.rsplitn(2, ':');
    let port_str = split.next()?;
    let addr = split.next().unwrap_or("*");
    let port = port_str.parse::<u16>().ok()?;
    Some((addr.to_string(), port))
}

#[tauri::command]
pub async fn list_active_ports() -> Result<Vec<ActivePort>, String> {
    let output = run_command("lsof", &["-iTCP", "-sTCP:LISTEN", "-P", "-n"]).await?;
    Ok(parse_ports(&output))
}

#[tauri::command]
pub async fn kill_port(pid: i32) -> Result<String, String> {
    run_command("kill", &["-9", &pid.to_string()]).await
}
