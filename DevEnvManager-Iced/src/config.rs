use serde::{Deserialize, Serialize};
use std::fmt;
use std::fs;
use std::path::PathBuf;

const CONFIG_ENV_DIR: &str = "DEVENV_MANAGER_ICED_CONFIG_DIR";
const CONFIG_FILE_NAME: &str = "config.toml";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub refresh_interval_secs: u64,
    pub launch_at_login: bool,
    pub show_notifications: bool,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            refresh_interval_secs: 60,
            launch_at_login: false,
            show_notifications: true,
        }
    }
}

impl AppConfig {
    pub fn load() -> Self {
        match Self::load_from_disk() {
            Ok(config) => config,
            Err(error) => {
                eprintln!("Failed to load config: {error}");
                Self::default()
            }
        }
    }

    pub fn save(&self) -> Result<(), ConfigError> {
        let path = config_path()?;
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(ConfigError::Io)?;
        }

        let contents = toml::to_string_pretty(self).map_err(ConfigError::TomlEncode)?;
        fs::write(&path, contents).map_err(ConfigError::Io)?;
        Ok(())
    }

    fn load_from_disk() -> Result<Self, ConfigError> {
        let path = config_path()?;
        let contents = fs::read_to_string(&path).map_err(ConfigError::Io)?;
        toml::from_str(&contents).map_err(ConfigError::TomlDecode)
    }
}

#[derive(Debug)]
pub enum ConfigError {
    Io(std::io::Error),
    TomlDecode(toml::de::Error),
    TomlEncode(toml::ser::Error),
    MissingHome,
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ConfigError::Io(error) => write!(f, "io error: {error}"),
            ConfigError::TomlDecode(error) => write!(f, "toml decode error: {error}"),
            ConfigError::TomlEncode(error) => write!(f, "toml encode error: {error}"),
            ConfigError::MissingHome => write!(f, "HOME environment variable not set"),
        }
    }
}

impl std::error::Error for ConfigError {}

fn config_path() -> Result<PathBuf, ConfigError> {
    if let Ok(override_dir) = std::env::var(CONFIG_ENV_DIR) {
        return Ok(PathBuf::from(override_dir).join(CONFIG_FILE_NAME));
    }

    let home = std::env::var("HOME").map_err(|_| ConfigError::MissingHome)?;
    Ok(PathBuf::from(home)
        .join(".config")
        .join("dev-env")
        .join("DevEnvManager-Iced")
        .join(CONFIG_FILE_NAME))
}
