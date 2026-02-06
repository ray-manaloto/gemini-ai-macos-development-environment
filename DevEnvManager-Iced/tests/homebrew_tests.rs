#[cfg(test)]
mod tests {
    use devenv_manager_iced::domain::homebrew::parse_services_output;
    use devenv_manager_iced::models::ServiceStatus;

    #[test]
    fn parses_brew_services_output() {
        let output = r#"Name          Status  User   File
redis         started test   ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
postgresql@15 stopped
nginx         error   256    test   ~/Library/LaunchAgents/homebrew.mxcl.nginx.plist
"#;

        let services = parse_services_output(output);
        assert_eq!(services.len(), 3);

        let redis = services.iter().find(|svc| svc.name == "redis").expect("redis service");
        assert_eq!(redis.status, ServiceStatus::Started);

        let postgres = services
            .iter()
            .find(|svc| svc.name == "postgresql@15")
            .expect("postgres service");
        assert_eq!(postgres.status, ServiceStatus::Stopped);

        let nginx = services.iter().find(|svc| svc.name == "nginx").expect("nginx service");
        assert_eq!(nginx.status, ServiceStatus::Error);
        assert_eq!(nginx.exit_code, Some(256));
    }
}
