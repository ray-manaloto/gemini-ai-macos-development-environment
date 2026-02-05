#[cfg(test)]
mod tests {
    use devenv_manager_iced::domain::mise::parse_tools_json;

    #[test]
    fn parses_mise_tools_json() {
        let json = r#"{
  "node": [
    {
      "version": "20.10.0",
      "requested_version": "latest",
      "install_path": "/Users/test/.local/share/mise/installs/node",
      "source": { "type": "tool-versions", "path": "/Users/test/.tool-versions" },
      "installed": true
    }
  ],
  "bun": [
    {
      "version": "1.0.0",
      "requested_version": null,
      "install_path": null,
      "source": null,
      "installed": false
    }
  ]
}"#;

        let tools = parse_tools_json(json).expect("parse tools json");
        assert_eq!(tools.len(), 2);

        let node = tools.iter().find(|tool| tool.name == "node").expect("node tool");
        assert_eq!(node.version, "20.10.0");
        assert!(node.installed);

        let bun = tools.iter().find(|tool| tool.name == "bun").expect("bun tool");
        assert!(!bun.installed);
    }
}
