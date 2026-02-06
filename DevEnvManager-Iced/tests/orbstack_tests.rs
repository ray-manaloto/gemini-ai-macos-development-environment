#[cfg(test)]
mod tests {
    use devenv_manager_iced::domain::orbstack::parse_containers_output;
    use devenv_manager_iced::models::ContainerState;

    #[test]
    fn parses_multiple_containers_different_states() {
        let output = r#"NAME          STATE      IMAGE
api           running    ubuntu:22.04
db            stopped    postgres:16
worker        exited     node:20
"#;

        let containers = parse_containers_output(output);
        assert_eq!(containers.len(), 3);

        let api = containers.iter().find(|c| c.name == "api").expect("api container");
        assert_eq!(api.state, ContainerState::Running);
        assert_eq!(api.image.as_deref(), Some("ubuntu:22.04"));
        assert_eq!(api.status.as_deref(), Some("running"));

        let db = containers.iter().find(|c| c.name == "db").expect("db container");
        assert_eq!(db.state, ContainerState::Stopped);
        assert_eq!(db.image.as_deref(), Some("postgres:16"));

        let worker = containers.iter().find(|c| c.name == "worker").expect("worker container");
        assert_eq!(worker.state, ContainerState::Unknown);
        assert_eq!(worker.image.as_deref(), Some("node:20"));
    }

    #[test]
    fn parses_empty_output() {
        let containers = parse_containers_output("");
        assert!(containers.is_empty());
    }

    #[test]
    fn parses_only_header_line() {
        let output = "NAME          STATE      IMAGE\n";
        let containers = parse_containers_output(output);
        assert!(containers.is_empty());
    }

    #[test]
    fn skips_blank_lines() {
        let output = r#"NAME          STATE      IMAGE

api           running    ubuntu:22.04

db            stopped    postgres:16

"#;

        let containers = parse_containers_output(output);
        assert_eq!(containers.len(), 2);
    }

    #[test]
    fn parses_malformed_lines_with_missing_fields() {
        // A line with only a name and no status should still be parsed
        // (status becomes "unknown", image becomes None)
        let output = r#"NAME          STATE      IMAGE
lonely
api           running    ubuntu:22.04
"#;

        let containers = parse_containers_output(output);
        // "lonely" has no status token, so parts.next() for status returns None → unwrap_or("unknown")
        // That means it still creates a container with state Unknown
        assert_eq!(containers.len(), 2);

        let lonely = containers.iter().find(|c| c.name == "lonely").expect("lonely container");
        assert_eq!(lonely.state, ContainerState::Unknown);
        assert!(lonely.image.is_none());
    }

    #[test]
    fn parses_container_names_with_special_characters() {
        let output = r#"NAME               STATE      IMAGE
my-web-app         running    nginx:latest
db_primary_01      stopped    postgres:16
project.backend    running    node:20
"#;

        let containers = parse_containers_output(output);
        assert_eq!(containers.len(), 3);

        assert!(containers.iter().any(|c| c.name == "my-web-app"));
        assert!(containers.iter().any(|c| c.name == "db_primary_01"));
        assert!(containers.iter().any(|c| c.name == "project.backend"));
    }

    #[test]
    fn parses_containers_without_image_field() {
        let output = r#"NAME          STATE
api           running
db            stopped
"#;

        let containers = parse_containers_output(output);
        assert_eq!(containers.len(), 2);

        let api = containers.iter().find(|c| c.name == "api").expect("api container");
        assert_eq!(api.state, ContainerState::Running);
        assert!(api.image.is_none());
    }

    #[test]
    fn header_detection_is_case_insensitive() {
        // The parser checks line.to_lowercase().contains("name") for index == 0
        let output = "Name          State      Image\napi           running    ubuntu:22.04\n";
        let containers = parse_containers_output(output);
        assert_eq!(containers.len(), 1);
        assert_eq!(containers[0].name, "api");
    }
}
