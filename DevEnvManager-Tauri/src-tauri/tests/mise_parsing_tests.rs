use devenv_manager_tauri_lib::commands::mise;

#[test]
fn parse_multiple_backends() {
    let json = r#"
    {
      "node": [
        {
          "version": "22.12.0",
          "requested_version": "22",
          "install_path": "/Users/test/.local/share/mise/installs/node/22.12.0",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ],
      "python": [
        {
          "version": "3.12.4",
          "requested_version": "3.12",
          "install_path": "/Users/test/.local/share/mise/installs/python/3.12.4",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ],
      "bun": [
        {
          "version": "1.2.0",
          "requested_version": "latest",
          "install_path": "/Users/test/.local/share/mise/installs/bun/1.2.0",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ],
      "go": [
        {
          "version": "1.23.0",
          "requested_version": "1.23",
          "install_path": "/Users/test/.local/share/mise/installs/go/1.23.0",
          "source": { "type": ".tool-versions", "path": ".tool-versions" },
          "installed": true
        }
      ],
      "ruby": [
        {
          "version": "3.3.5",
          "requested_version": "3.3",
          "install_path": "/Users/test/.local/share/mise/installs/ruby/3.3.5",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse multiple backends");
    assert_eq!(tools.len(), 5);

    // BTreeMap produces sorted keys
    let names: Vec<&str> = tools.iter().map(|t| t.name.as_str()).collect();
    assert_eq!(names, vec!["bun", "go", "node", "python", "ruby"]);

    let node = tools.iter().find(|t| t.name == "node").unwrap();
    assert_eq!(node.version, "22.12.0");
    assert_eq!(node.requested_version.as_deref(), Some("22"));
    assert!(node.installed);

    let python = tools.iter().find(|t| t.name == "python").unwrap();
    assert_eq!(python.version, "3.12.4");
}

#[test]
fn parse_empty_tool_list() {
    let json = "{}";
    let tools = mise::parse_mise_tools(json).expect("parse empty tool list");
    assert!(tools.is_empty());
}

#[test]
fn parse_tool_with_missing_optional_fields() {
    let json = r#"
    {
      "deno": [
        {
          "version": "2.1.0",
          "requested_version": null,
          "install_path": null,
          "source": null,
          "installed": false
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse missing optional fields");
    assert_eq!(tools.len(), 1);
    assert_eq!(tools[0].name, "deno");
    assert_eq!(tools[0].version, "2.1.0");
    assert!(tools[0].requested_version.is_none());
    assert!(tools[0].install_path.is_none());
    assert!(tools[0].source.is_none());
    assert!(!tools[0].installed);
}

#[test]
fn parse_tool_with_non_standard_source_type() {
    let json = r#"
    {
      "usage": [
        {
          "version": "1.5.0",
          "requested_version": "latest",
          "install_path": "/Users/test/.local/share/mise/installs/usage/1.5.0",
          "source": { "type": "ubi", "path": null },
          "installed": true
        }
      ],
      "cargo:ast-grep": [
        {
          "version": "0.37.0",
          "requested_version": "latest",
          "install_path": "/Users/test/.local/share/mise/installs/cargo:ast-grep/0.37.0",
          "source": { "type": "cargo", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse non-standard source");
    assert_eq!(tools.len(), 2);

    let ast_grep = tools.iter().find(|t| t.name == "cargo:ast-grep").unwrap();
    let source = ast_grep.source.as_ref().unwrap();
    assert_eq!(source.r#type.as_deref(), Some("cargo"));

    let usage = tools.iter().find(|t| t.name == "usage").unwrap();
    let source = usage.source.as_ref().unwrap();
    assert_eq!(source.r#type.as_deref(), Some("ubi"));
    assert!(source.path.is_none());
}

#[test]
fn parse_tool_with_multiple_versions() {
    let json = r#"
    {
      "python": [
        {
          "version": "3.11.9",
          "requested_version": "3.11",
          "install_path": "/Users/test/.local/share/mise/installs/python/3.11.9",
          "source": { "type": "mise.toml", "path": "~/project/.mise.toml" },
          "installed": true
        },
        {
          "version": "3.12.4",
          "requested_version": "3.12",
          "install_path": "/Users/test/.local/share/mise/installs/python/3.12.4",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse multiple versions");
    assert_eq!(tools.len(), 2);
    assert_eq!(tools[0].name, "python");
    assert_eq!(tools[0].version, "3.11.9");
    assert_eq!(tools[1].name, "python");
    assert_eq!(tools[1].version, "3.12.4");
}

#[test]
fn parse_invalid_json_returns_error() {
    let bad_json = "this is not json";
    let result = mise::parse_mise_tools(bad_json);
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert!(err.contains("Failed to parse mise output"));
}

#[test]
fn parse_tool_with_empty_version_array() {
    let json = r#"
    {
      "node": [],
      "bun": [
        {
          "version": "1.2.0",
          "requested_version": "latest",
          "install_path": "/Users/test/.local/share/mise/installs/bun/1.2.0",
          "source": { "type": "mise.toml", "path": "~/.config/mise/config.toml" },
          "installed": true
        }
      ]
    }
    "#;

    let tools = mise::parse_mise_tools(json).expect("parse empty version array");
    assert_eq!(tools.len(), 1);
    assert_eq!(tools[0].name, "bun");
}
