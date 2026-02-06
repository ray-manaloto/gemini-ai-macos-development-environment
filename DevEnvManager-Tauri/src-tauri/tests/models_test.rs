use devenv_manager_tauri_lib::models::{
    ActivePort, BrewService, BrewServiceStatus, Container, ContainerState, MiseTool, MiseToolSource,
};

#[test]
fn serializes_mise_tool() {
    let tool = MiseTool {
        name: "bun".to_string(),
        version: "1.1.0".to_string(),
        requested_version: Some("1.1.0".to_string()),
        install_path: Some("/path".to_string()),
        source: Some(MiseToolSource {
            r#type: Some("tool".to_string()),
            path: Some(".tool-versions".to_string()),
        }),
        installed: true,
    };

    let json = serde_json::to_string(&tool).expect("serialize mise tool");
    let decoded: MiseTool = serde_json::from_str(&json).expect("deserialize mise tool");
    assert_eq!(decoded, tool);
}

#[test]
fn serializes_brew_service() {
    let service = BrewService {
        name: "redis".to_string(),
        status: BrewServiceStatus::Started,
        user: Some("ray".to_string()),
        file: Some("/path".to_string()),
        exit_code: None,
        port: Some(6379),
        pid: Some(1234),
    };

    let json = serde_json::to_string(&service).expect("serialize service");
    let decoded: BrewService = serde_json::from_str(&json).expect("deserialize service");
    assert_eq!(decoded, service);
}

#[test]
fn serializes_container() {
    let container = Container {
        id: "app".to_string(),
        name: "app".to_string(),
        image: "image".to_string(),
        state: ContainerState::Running,
        status: "running".to_string(),
        ports: vec!["0.0.0.0:3000".to_string()],
    };

    let json = serde_json::to_string(&container).expect("serialize container");
    let decoded: Container = serde_json::from_str(&json).expect("deserialize container");
    assert_eq!(decoded, container);
}

#[test]
fn serializes_active_port() {
    let port = ActivePort {
        protocol: "TCP".to_string(),
        local_address: "*".to_string(),
        port: 3000,
        process: "node".to_string(),
        pid: 123,
    };

    let json = serde_json::to_string(&port).expect("serialize port");
    let decoded: ActivePort = serde_json::from_str(&json).expect("deserialize port");
    assert_eq!(decoded, port);
}
