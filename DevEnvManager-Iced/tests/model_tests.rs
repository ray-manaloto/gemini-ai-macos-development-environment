#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use devenv_manager_iced::config::AppConfig;
    use devenv_manager_iced::models::{Container, ContainerState, Service, ServiceStatus, Tool};

    #[test]
    fn serializes_models() {
        let tool = Tool {
            name: "node".to_string(),
            version: "20.10.0".to_string(),
            requested_version: Some("latest".to_string()),
            install_path: Some("/tmp".to_string()),
            source: None,
            installed: true,
        };

        let service = Service {
            name: "redis".to_string(),
            status: ServiceStatus::Started,
            user: Some("test".to_string()),
            file: None,
            exit_code: None,
            port: Some(6379),
            pid: Some(1234),
        };

        let container = Container {
            name: "api".to_string(),
            image: Some("my-image".to_string()),
            state: ContainerState::Running,
            status: Some("running".to_string()),
        };

        let tool_json = serde_json::to_string(&tool).expect("serialize tool");
        let service_json = serde_json::to_string(&service).expect("serialize service");
        let container_json = serde_json::to_string(&container).expect("serialize container");

        let tool_back: Tool = serde_json::from_str(&tool_json).expect("deserialize tool");
        let service_back: Service = serde_json::from_str(&service_json).expect("deserialize service");
        let container_back: Container = serde_json::from_str(&container_json).expect("deserialize container");

        assert_eq!(tool_back, tool);
        assert_eq!(service_back, service);
        assert_eq!(container_back, container);
    }

    #[test]
    fn config_round_trip() {
        let suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("time")
            .as_millis();
        let temp_dir = std::env::temp_dir().join(format!("devenv-manager-iced-{suffix}"));

        std::fs::create_dir_all(&temp_dir).expect("create temp config dir");
        std::env::set_var("DEVENV_MANAGER_ICED_CONFIG_DIR", &temp_dir);

        let config = AppConfig {
            refresh_interval_secs: 30,
            launch_at_login: true,
            show_notifications: false,
        };

        config.save().expect("save config");
        let loaded = AppConfig::load();

        assert_eq!(loaded.refresh_interval_secs, 30);
        assert!(loaded.launch_at_login);
        assert!(!loaded.show_notifications);

        std::env::remove_var("DEVENV_MANAGER_ICED_CONFIG_DIR");
    }
}
