use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ServiceStatus {
    Started,
    Stopped,
    Error,
    None,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Service {
    pub name: String,
    pub status: ServiceStatus,
    pub user: Option<String>,
    pub file: Option<String>,
    #[serde(rename = "exit_code")]
    pub exit_code: Option<i32>,
    pub port: Option<u16>,
    pub pid: Option<i32>,
}

impl Service {
    pub fn display_name(&self) -> String {
        self.name.replace("homebrew.mxcl.", "")
    }

    pub fn is_running(&self) -> bool {
        matches!(self.status, ServiceStatus::Started)
    }
}

impl ServiceStatus {
    pub fn display_name(&self) -> &'static str {
        match self {
            ServiceStatus::Started => "Started",
            ServiceStatus::Stopped => "Stopped",
            ServiceStatus::Error => "Error",
            ServiceStatus::None => "None",
            ServiceStatus::Unknown => "Unknown",
        }
    }
}
