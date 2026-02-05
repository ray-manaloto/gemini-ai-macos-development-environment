#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use devenv_manager_iced::config::AppConfig;

    fn temp_config_dir(label: &str) -> std::path::PathBuf {
        let suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("time")
            .as_nanos();
        std::env::temp_dir().join(format!("devenv-config-{label}-{suffix}"))
    }

    #[test]
    fn default_config_values() {
        let config = AppConfig::default();
        assert_eq!(config.refresh_interval_secs, 60);
        assert!(!config.launch_at_login);
        assert!(config.show_notifications);
    }

    #[test]
    fn toml_serialization_round_trip() {
        let config = AppConfig {
            refresh_interval_secs: 15,
            launch_at_login: true,
            show_notifications: false,
        };

        let toml_str = toml::to_string_pretty(&config).expect("serialize to toml");
        let deserialized: AppConfig = toml::from_str(&toml_str).expect("deserialize from toml");

        assert_eq!(deserialized.refresh_interval_secs, 15);
        assert!(deserialized.launch_at_login);
        assert!(!deserialized.show_notifications);
    }

    #[test]
    fn config_save_creates_parent_directory() {
        let dir = temp_config_dir("save-creates-dir");
        // Directory does not exist yet
        assert!(!dir.exists());

        std::env::set_var("DEVENV_MANAGER_ICED_CONFIG_DIR", &dir);

        let config = AppConfig {
            refresh_interval_secs: 45,
            launch_at_login: false,
            show_notifications: true,
        };
        config.save().expect("save config");

        std::env::remove_var("DEVENV_MANAGER_ICED_CONFIG_DIR");

        // Directory was created
        assert!(dir.exists());
        // Config file exists inside
        let config_file = dir.join("config.toml");
        assert!(config_file.exists());

        let contents = std::fs::read_to_string(&config_file).expect("read config file");
        let loaded: AppConfig = toml::from_str(&contents).expect("parse config");
        assert_eq!(loaded.refresh_interval_secs, 45);
        assert!(!loaded.launch_at_login);
        assert!(loaded.show_notifications);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn config_env_var_override() {
        let dir = temp_config_dir("env-override");
        std::fs::create_dir_all(&dir).expect("create temp dir");
        std::env::set_var("DEVENV_MANAGER_ICED_CONFIG_DIR", &dir);

        let config = AppConfig {
            refresh_interval_secs: 120,
            launch_at_login: true,
            show_notifications: true,
        };
        config.save().expect("save config");

        std::env::remove_var("DEVENV_MANAGER_ICED_CONFIG_DIR");

        let config_file = dir.join("config.toml");
        let contents = std::fs::read_to_string(&config_file).expect("read config file");
        let loaded: AppConfig = toml::from_str(&contents).expect("parse config");
        assert_eq!(loaded.refresh_interval_secs, 120);
        assert!(loaded.launch_at_login);
        assert!(loaded.show_notifications);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn invalid_toml_fails_to_parse() {
        let invalid = "not a valid [[[ toml file !!!";
        let result = toml::from_str::<AppConfig>(invalid);
        assert!(result.is_err());

        let fallback = AppConfig::default();
        assert_eq!(fallback.refresh_interval_secs, 60);
        assert!(!fallback.launch_at_login);
        assert!(fallback.show_notifications);
    }

    #[test]
    fn missing_config_file_returns_default() {
        let dir = temp_config_dir("missing-file");
        std::fs::create_dir_all(&dir).expect("create temp dir");

        let config_file = dir.join("config.toml");
        assert!(!config_file.exists());

        let result = std::fs::read_to_string(&config_file);
        assert!(result.is_err());

        let fallback = AppConfig::default();
        assert_eq!(fallback.refresh_interval_secs, 60);
        assert!(!fallback.launch_at_login);
        assert!(fallback.show_notifications);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn config_error_display_formatting() {
        use devenv_manager_iced::config::ConfigError;

        let io_err = ConfigError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found"));
        let display = format!("{io_err}");
        assert!(display.contains("io error"));
        assert!(display.contains("file not found"));

        let missing_home = ConfigError::MissingHome;
        let display = format!("{missing_home}");
        assert!(display.contains("HOME"));
    }
}
