use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Tool {
    pub name: String,
    pub version: String,
    #[serde(rename = "requested_version")]
    pub requested_version: Option<String>,
    #[serde(rename = "install_path")]
    pub install_path: Option<String>,
    pub source: Option<ToolSource>,
    pub installed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ToolSource {
    #[serde(rename = "type")]
    pub source_type: Option<String>,
    pub path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ToolStatus {
    Installed,
    Outdated,
    Missing,
    Unknown,
}

impl Tool {
    pub fn display_name(&self) -> String {
        self.name
            .split('_')
            .map(|part| {
                let mut chars = part.chars();
                match chars.next() {
                    Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                    None => String::new(),
                }
            })
            .collect::<Vec<_>>()
            .join(" ")
    }

    pub fn display_version(&self) -> String {
        if self.version == "system" {
            "system".to_string()
        } else {
            self.version.clone()
        }
    }

    pub fn status(&self) -> ToolStatus {
        if !self.installed {
            ToolStatus::Missing
        } else {
            ToolStatus::Installed
        }
    }
}

impl ToolStatus {
    pub fn display_name(&self) -> &'static str {
        match self {
            ToolStatus::Installed => "Installed",
            ToolStatus::Outdated => "Update Available",
            ToolStatus::Missing => "Not Installed",
            ToolStatus::Unknown => "Unknown",
        }
    }
}
