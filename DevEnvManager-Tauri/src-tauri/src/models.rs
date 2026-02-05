use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MiseTool {
    pub name: String,
    pub version: String,
    pub requested_version: Option<String>,
    pub install_path: Option<String>,
    pub source: Option<MiseToolSource>,
    pub installed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MiseToolSource {
    pub r#type: Option<String>,
    pub path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum BrewServiceStatus {
    Started,
    Stopped,
    Error,
    None,
    Unknown,
}

impl BrewServiceStatus {
    pub fn from_raw(raw: &str) -> Self {
        match raw.to_lowercase().as_str() {
            "started" => BrewServiceStatus::Started,
            "stopped" => BrewServiceStatus::Stopped,
            "error" => BrewServiceStatus::Error,
            "none" => BrewServiceStatus::None,
            _ => BrewServiceStatus::Unknown,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct BrewService {
    pub name: String,
    pub status: BrewServiceStatus,
    pub user: Option<String>,
    pub file: Option<String>,
    pub exit_code: Option<i32>,
    pub port: Option<u16>,
    pub pid: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ContainerState {
    Running,
    Stopped,
    Paused,
    Exited,
    Unknown,
}

impl ContainerState {
    pub fn from_raw(raw: &str) -> Self {
        match raw.to_lowercase().as_str() {
            "running" => ContainerState::Running,
            "stopped" => ContainerState::Stopped,
            "paused" => ContainerState::Paused,
            "exited" => ContainerState::Exited,
            _ => ContainerState::Unknown,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Container {
    pub id: String,
    pub name: String,
    pub image: String,
    pub state: ContainerState,
    pub status: String,
    pub ports: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ActivePort {
    pub protocol: String,
    pub local_address: String,
    pub port: u16,
    pub process: String,
    pub pid: i32,
}
