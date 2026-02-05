use std::collections::BTreeMap;

use serde::Deserialize;
use tokio::process::Command;

use crate::models::{Tool, ToolSource};

const MISE_ENV: [(&str, &str); 2] = [("MISE_YES", "1"), ("MISE_QUIET", "0")];

pub async fn list_tools() -> Vec<Tool> {
    let output = Command::new("mise")
        .args(["ls", "--json"])
        .envs(MISE_ENV)
        .output()
        .await;

    let output = match output {
        Ok(output) => output,
        Err(error) => {
            eprintln!("Failed to run mise ls: {error}");
            return Vec::new();
        }
    };

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("mise ls failed: {stderr}");
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    match parse_tools_json(&stdout) {
        Ok(tools) => tools,
        Err(error) => {
            eprintln!("Failed to parse mise output: {error}");
            Vec::new()
        }
    }
}

pub async fn install_tool(name: String) {
    let target = format!("{name}@latest");
    if let Err(error) = run_mise(["use", "-g", &target]).await {
        eprintln!("Failed to install {name}: {error}");
    }
}

pub async fn update_tool(name: String) {
    let target = format!("{name}@latest");
    if let Err(error) = run_mise(["use", "-g", &target]).await {
        eprintln!("Failed to update {name}: {error}");
    }
}

async fn run_mise<const N: usize>(args: [&str; N]) -> Result<(), String> {
    let output = Command::new("mise")
        .args(args)
        .envs(MISE_ENV)
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

pub fn parse_tools_json(output: &str) -> Result<Vec<Tool>, String> {
    let map: BTreeMap<String, Vec<ToolEntry>> =
        serde_json::from_str(output).map_err(|error| error.to_string())?;
    let mut tools = Vec::new();

    for (name, entries) in map {
        for entry in entries {
            tools.push(Tool {
                name: name.clone(),
                version: entry.version,
                requested_version: entry.requested_version,
                install_path: entry.install_path,
                source: entry.source.map(|source| ToolSource {
                    source_type: source.source_type,
                    path: source.path,
                }),
                installed: entry.installed,
            });
        }
    }

    tools.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(tools)
}

#[derive(Debug, Deserialize)]
struct ToolEntry {
    version: String,
    #[serde(rename = "requested_version")]
    requested_version: Option<String>,
    #[serde(rename = "install_path")]
    install_path: Option<String>,
    source: Option<ToolSourceEntry>,
    installed: bool,
}

#[derive(Debug, Deserialize)]
struct ToolSourceEntry {
    #[serde(rename = "type")]
    source_type: Option<String>,
    path: Option<String>,
}
