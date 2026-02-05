#[cfg(test)]
mod tests {
    use devenv_manager_iced::app::{PopupTab, WindowKind};
    use devenv_manager_iced::models::{
        Container, ContainerState, Service, ServiceStatus, Tool, ToolSource, ToolStatus,
    };

    // --- WindowKind enum ---

    #[test]
    fn window_kind_equality() {
        assert_eq!(WindowKind::Popup, WindowKind::Popup);
        assert_eq!(WindowKind::Settings, WindowKind::Settings);
        assert_ne!(WindowKind::Popup, WindowKind::Settings);
    }

    #[test]
    fn window_kind_is_copy() {
        let kind = WindowKind::Popup;
        let copied = kind;
        // Both still usable because WindowKind is Copy
        assert_eq!(kind, copied);
    }

    #[test]
    fn window_kind_debug() {
        let debug = format!("{:?}", WindowKind::Popup);
        assert_eq!(debug, "Popup");
        let debug = format!("{:?}", WindowKind::Settings);
        assert_eq!(debug, "Settings");
    }

    // --- PopupTab enum ---

    #[test]
    fn popup_tab_equality() {
        assert_eq!(PopupTab::Tools, PopupTab::Tools);
        assert_eq!(PopupTab::Services, PopupTab::Services);
        assert_eq!(PopupTab::Containers, PopupTab::Containers);
        assert_ne!(PopupTab::Tools, PopupTab::Services);
        assert_ne!(PopupTab::Tools, PopupTab::Containers);
        assert_ne!(PopupTab::Services, PopupTab::Containers);
    }

    #[test]
    fn popup_tab_is_copy() {
        let tab = PopupTab::Containers;
        let copied = tab;
        assert_eq!(tab, copied);
    }

    #[test]
    fn popup_tab_debug() {
        assert_eq!(format!("{:?}", PopupTab::Tools), "Tools");
        assert_eq!(format!("{:?}", PopupTab::Services), "Services");
        assert_eq!(format!("{:?}", PopupTab::Containers), "Containers");
    }

    // --- Tool model methods ---

    #[test]
    fn tool_display_name_capitalizes_underscored_parts() {
        let tool = Tool {
            name: "fd_find".to_string(),
            version: "9.0.0".to_string(),
            requested_version: None,
            install_path: None,
            source: None,
            installed: true,
        };
        assert_eq!(tool.display_name(), "Fd Find");
    }

    #[test]
    fn tool_display_name_single_word() {
        let tool = Tool {
            name: "bun".to_string(),
            version: "1.0.0".to_string(),
            requested_version: None,
            install_path: None,
            source: None,
            installed: true,
        };
        assert_eq!(tool.display_name(), "Bun");
    }

    #[test]
    fn tool_display_version_system() {
        let tool = Tool {
            name: "python".to_string(),
            version: "system".to_string(),
            requested_version: None,
            install_path: None,
            source: None,
            installed: true,
        };
        assert_eq!(tool.display_version(), "system");
    }

    #[test]
    fn tool_display_version_specific() {
        let tool = Tool {
            name: "node".to_string(),
            version: "20.10.0".to_string(),
            requested_version: Some("latest".to_string()),
            install_path: Some("/tmp".to_string()),
            source: None,
            installed: true,
        };
        assert_eq!(tool.display_version(), "20.10.0");
    }

    #[test]
    fn tool_status_installed() {
        let tool = Tool {
            name: "node".to_string(),
            version: "20.10.0".to_string(),
            requested_version: None,
            install_path: None,
            source: None,
            installed: true,
        };
        assert!(matches!(tool.status(), ToolStatus::Installed));
    }

    #[test]
    fn tool_status_missing() {
        let tool = Tool {
            name: "ruby".to_string(),
            version: "3.2.0".to_string(),
            requested_version: None,
            install_path: None,
            source: None,
            installed: false,
        };
        assert!(matches!(tool.status(), ToolStatus::Missing));
    }

    #[test]
    fn tool_status_display_names() {
        assert_eq!(ToolStatus::Installed.display_name(), "Installed");
        assert_eq!(ToolStatus::Outdated.display_name(), "Update Available");
        assert_eq!(ToolStatus::Missing.display_name(), "Not Installed");
        assert_eq!(ToolStatus::Unknown.display_name(), "Unknown");
    }

    #[test]
    fn tool_source_fields() {
        let source = ToolSource {
            source_type: Some("tool-versions".to_string()),
            path: Some("/home/user/.tool-versions".to_string()),
        };
        assert_eq!(source.source_type.as_deref(), Some("tool-versions"));
        assert_eq!(source.path.as_deref(), Some("/home/user/.tool-versions"));
    }

    // --- Service model methods ---

    #[test]
    fn service_display_name_strips_homebrew_prefix() {
        let service = Service {
            name: "homebrew.mxcl.redis".to_string(),
            status: ServiceStatus::Started,
            user: None,
            file: None,
            exit_code: None,
            port: None,
            pid: None,
        };
        assert_eq!(service.display_name(), "redis");
    }

    #[test]
    fn service_display_name_without_prefix() {
        let service = Service {
            name: "nginx".to_string(),
            status: ServiceStatus::Stopped,
            user: None,
            file: None,
            exit_code: None,
            port: None,
            pid: None,
        };
        assert_eq!(service.display_name(), "nginx");
    }

    #[test]
    fn service_is_running_true() {
        let service = Service {
            name: "redis".to_string(),
            status: ServiceStatus::Started,
            user: None,
            file: None,
            exit_code: None,
            port: None,
            pid: None,
        };
        assert!(service.is_running());
    }

    #[test]
    fn service_is_running_false_for_other_states() {
        for status in [
            ServiceStatus::Stopped,
            ServiceStatus::Error,
            ServiceStatus::None,
            ServiceStatus::Unknown,
        ] {
            let service = Service {
                name: "test".to_string(),
                status,
                user: None,
                file: None,
                exit_code: None,
                port: None,
                pid: None,
            };
            assert!(!service.is_running());
        }
    }

    #[test]
    fn service_status_display_names() {
        assert_eq!(ServiceStatus::Started.display_name(), "Started");
        assert_eq!(ServiceStatus::Stopped.display_name(), "Stopped");
        assert_eq!(ServiceStatus::Error.display_name(), "Error");
        assert_eq!(ServiceStatus::None.display_name(), "None");
        assert_eq!(ServiceStatus::Unknown.display_name(), "Unknown");
    }

    // --- Container model methods ---

    #[test]
    fn container_display_status() {
        let running = Container {
            name: "api".to_string(),
            image: None,
            state: ContainerState::Running,
            status: None,
        };
        assert_eq!(running.display_status(), "Running");

        let stopped = Container {
            name: "db".to_string(),
            image: None,
            state: ContainerState::Stopped,
            status: None,
        };
        assert_eq!(stopped.display_status(), "Stopped");

        let unknown = Container {
            name: "worker".to_string(),
            image: None,
            state: ContainerState::Unknown,
            status: None,
        };
        assert_eq!(unknown.display_status(), "Unknown");
    }

    #[test]
    fn container_state_serde_round_trip() {
        let container = Container {
            name: "web".to_string(),
            image: Some("nginx:latest".to_string()),
            state: ContainerState::Running,
            status: Some("running".to_string()),
        };

        let json = serde_json::to_string(&container).expect("serialize");
        let back: Container = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(back.name, "web");
        assert_eq!(back.state, ContainerState::Running);
        assert_eq!(back.image.as_deref(), Some("nginx:latest"));
    }
}
