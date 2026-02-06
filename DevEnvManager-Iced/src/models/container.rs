use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ContainerState {
    Running,
    Stopped,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Container {
    pub name: String,
    pub image: Option<String>,
    pub state: ContainerState,
    pub status: Option<String>,
}

impl Container {
    pub fn display_status(&self) -> &'static str {
        match self.state {
            ContainerState::Running => "Running",
            ContainerState::Stopped => "Stopped",
            ContainerState::Unknown => "Unknown",
        }
    }
}
