use serde::Serialize;

use crate::commands::run_command;

#[derive(Debug, Serialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum CloudStatus {
    Connected,
    Disconnected,
    NotInstalled,
    Unknown,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SkyPilotStatus {
    status: CloudStatus,
    cluster_count: usize,
    clusters: Vec<SkyPilotCluster>,
    message: Option<String>,
}

#[derive(Debug, Serialize, Clone)]
pub struct SkyPilotCluster {
    name: String,
    status: String,
    resources: String,
    region: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AwsStatus {
    status: CloudStatus,
    account_id: Option<String>,
    region: Option<String>,
    message: Option<String>,
}

#[tauri::command]
pub async fn get_skypilot_status() -> Result<SkyPilotStatus, String> {
    // Check if sky is installed
    let version_check = run_command("sky", &["--version"]).await;
    if version_check.is_err() {
        return Ok(SkyPilotStatus {
            status: CloudStatus::NotInstalled,
            cluster_count: 0,
            clusters: Vec::new(),
            message: Some("SkyPilot not installed".to_string()),
        });
    }

    // Get cluster status
    match run_command("sky", &["status"]).await {
        Ok(output) => {
            let clusters = parse_sky_status(&output);
            let cluster_count = clusters.len();
            let status = if cluster_count > 0 {
                CloudStatus::Connected
            } else {
                CloudStatus::Disconnected
            };

            Ok(SkyPilotStatus {
                status,
                cluster_count,
                clusters,
                message: None,
            })
        }
        Err(e) => Ok(SkyPilotStatus {
            status: CloudStatus::Unknown,
            cluster_count: 0,
            clusters: Vec::new(),
            message: Some(format!("Failed to get status: {e}")),
        }),
    }
}

fn parse_sky_status(output: &str) -> Vec<SkyPilotCluster> {
    let mut clusters = Vec::new();

    // Parse sky status output (text format)
    // Expected format:
    // NAME    STATUS  RESOURCES  REGION
    // agent   UP      1x AWS...  us-east-1
    for line in output.lines().skip(1) {
        // Skip header
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 3 {
            clusters.push(SkyPilotCluster {
                name: parts[0].to_string(),
                status: parts[1].to_string(),
                resources: parts[2..parts.len() - 1].join(" "),
                region: parts.last().map(|s| s.to_string()),
            });
        }
    }

    clusters
}

#[tauri::command]
pub async fn get_aws_status() -> Result<AwsStatus, String> {
    // Check if aws CLI is installed
    let version_check = run_command("aws", &["--version"]).await;
    if version_check.is_err() {
        return Ok(AwsStatus {
            status: CloudStatus::NotInstalled,
            account_id: None,
            region: None,
            message: Some("AWS CLI not installed".to_string()),
        });
    }

    // Check credentials
    match run_command("aws", &["sts", "get-caller-identity", "--output", "json"]).await {
        Ok(output) => {
            // Parse JSON output
            if let Ok(json) = serde_json::from_str::<serde_json::Value>(&output) {
                let account_id = json["Account"].as_str().map(|s| s.to_string());
                
                // Get region
                let region = run_command("aws", &["configure", "get", "region"])
                    .await
                    .ok()
                    .map(|r| r.trim().to_string());

                Ok(AwsStatus {
                    status: CloudStatus::Connected,
                    account_id,
                    region,
                    message: None,
                })
            } else {
                Ok(AwsStatus {
                    status: CloudStatus::Unknown,
                    account_id: None,
                    region: None,
                    message: Some("Failed to parse AWS response".to_string()),
                })
            }
        }
        Err(e) => Ok(AwsStatus {
            status: CloudStatus::Disconnected,
            account_id: None,
            region: None,
            message: Some(format!("Not configured: {e}")),
        }),
    }
}

#[tauri::command]
pub async fn launch_skypilot_agent() -> Result<String, String> {
    // Use mise task to launch agent
    run_command("mise", &["run", "agent:up"]).await
}

#[tauri::command]
pub async fn stop_skypilot_agents() -> Result<String, String> {
    // Stop all clusters
    run_command("sky", &["down", "-a", "-y"]).await
}

#[tauri::command]
pub async fn list_skypilot_clusters() -> Result<Vec<SkyPilotCluster>, String> {
    match run_command("sky", &["status"]).await {
        Ok(output) => Ok(parse_sky_status(&output)),
        Err(e) => Err(format!("Failed to list clusters: {e}")),
    }
}

#[tauri::command]
pub async fn stop_skypilot_cluster(name: String) -> Result<String, String> {
    run_command("sky", &["down", &name, "-y"]).await
}

#[tauri::command]
pub async fn ssh_skypilot_cluster(name: String) -> Result<String, String> {
    // Open terminal with SSH command
    let ssh_command = format!("sky ssh {name}");
    run_command("open", &["-a", "Terminal", &ssh_command]).await
}

#[tauri::command]
pub async fn get_skypilot_logs(name: String) -> Result<String, String> {
    run_command("sky", &["logs", &name]).await
}
