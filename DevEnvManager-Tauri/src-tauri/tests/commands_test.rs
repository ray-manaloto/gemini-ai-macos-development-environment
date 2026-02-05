use devenv_manager_tauri_lib::commands::{homebrew, mise, orbstack, ports};

#[test]
fn parses_mise_tools_json() {
    let json = r#"
    {
      "bun": [
        {
          "version": "1.1.0",
          "requested_version": "1.1.0",
          "install_path": "/Users/test/.local/share/mise/installs/bun/1.1.0",
          "source": { "type": "tool", "path": ".tool-versions" },
          "installed": true
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse mise tools");
    assert_eq!(tools.len(), 1);
    assert_eq!(tools[0].name, "bun");
    assert_eq!(tools[0].version, "1.1.0");
    assert!(tools[0].installed);
}

#[test]
fn parses_brew_services_output() {
    let output = "Name Status User File\nredis started ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.redis.plist\npostgresql stopped ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.postgresql.plist\n";
    let services = homebrew::parse_brew_services(output);
    assert_eq!(services.len(), 2);
    assert_eq!(services[0].name, "redis");
    assert_eq!(services[1].name, "postgresql");
}

#[test]
fn parses_orb_list_output() {
    let output = "NAME STATE\napp running\nworker stopped\n";
    let containers = orbstack::parse_orb_list(output);
    assert_eq!(containers.len(), 2);
    assert_eq!(containers[0].name, "app");
    assert_eq!(containers[1].name, "worker");
}

#[test]
fn parses_lsof_ports() {
    let output = "COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\nnode 123 ray 21u IPv4 0x123 0t0 TCP *:3000 (LISTEN)\n";
    let ports_list = ports::parse_ports(output);
    assert_eq!(ports_list.len(), 1);
    assert_eq!(ports_list[0].port, 3000);
}
