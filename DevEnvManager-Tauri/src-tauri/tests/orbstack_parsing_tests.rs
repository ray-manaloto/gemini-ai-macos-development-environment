use devenv_manager_tauri_lib::commands::orbstack;
use devenv_manager_tauri_lib::models::ContainerState;

#[test]
fn parse_containers_all_states() {
    let output = "\
NAME STATE STATUS
web running Up 3 hours
db paused Paused
worker exited Exited (0)
staging stopped Stopped
mystery custom_state Something
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 5);

    assert_eq!(containers[0].name, "web");
    assert_eq!(containers[0].state, ContainerState::Running);
    assert_eq!(containers[0].status, "Up");

    assert_eq!(containers[1].name, "db");
    assert_eq!(containers[1].state, ContainerState::Paused);

    assert_eq!(containers[2].name, "worker");
    assert_eq!(containers[2].state, ContainerState::Exited);

    assert_eq!(containers[3].name, "staging");
    assert_eq!(containers[3].state, ContainerState::Stopped);

    assert_eq!(containers[4].name, "mystery");
    assert_eq!(containers[4].state, ContainerState::Unknown);
}

#[test]
fn parse_empty_container_list() {
    let output = "NAME STATE\n";
    let containers = orbstack::parse_orb_list(output);
    assert!(containers.is_empty());
}

#[test]
fn parse_empty_container_list_with_blank_lines() {
    let output = "NAME STATE\n\n   \n\n";
    let containers = orbstack::parse_orb_list(output);
    assert!(containers.is_empty());
}

#[test]
fn parse_container_id_equals_name() {
    let output = "\
NAME STATE
myapp running
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 1);
    // The parser sets id = name
    assert_eq!(containers[0].id, "myapp");
    assert_eq!(containers[0].name, "myapp");
}

#[test]
fn parse_container_image_is_empty() {
    let output = "\
NAME STATE
myapp running
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 1);
    // The parser sets image to empty string
    assert!(containers[0].image.is_empty());
}

#[test]
fn parse_container_ports_is_empty_vec() {
    let output = "\
NAME STATE
myapp running
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 1);
    // The parser initializes ports to empty Vec
    assert!(containers[0].ports.is_empty());
}

#[test]
fn parse_compose_project_containers() {
    let output = "\
NAME STATE STATUS
project-web-1 running Up 45 minutes
project-db-1 running Up 45 minutes
project-redis-1 running Up 45 minutes
project-worker-1 exited Exited (1)
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 4);

    let names: Vec<&str> = containers.iter().map(|c| c.name.as_str()).collect();
    assert_eq!(
        names,
        vec![
            "project-web-1",
            "project-db-1",
            "project-redis-1",
            "project-worker-1"
        ]
    );

    assert_eq!(containers[3].state, ContainerState::Exited);
}

#[test]
fn from_raw_state_case_insensitive() {
    assert_eq!(ContainerState::from_raw("Running"), ContainerState::Running);
    assert_eq!(ContainerState::from_raw("RUNNING"), ContainerState::Running);
    assert_eq!(ContainerState::from_raw("PAUSED"), ContainerState::Paused);
    assert_eq!(ContainerState::from_raw("Exited"), ContainerState::Exited);
    assert_eq!(ContainerState::from_raw("STOPPED"), ContainerState::Stopped);
    assert_eq!(ContainerState::from_raw("created"), ContainerState::Unknown);
    assert_eq!(ContainerState::from_raw(""), ContainerState::Unknown);
}

#[test]
fn parse_single_column_line_skipped() {
    // Lines with < 2 parts should be skipped
    let output = "\
NAME STATE
onlyname
another running
";

    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 1);
    assert_eq!(containers[0].name, "another");
}
