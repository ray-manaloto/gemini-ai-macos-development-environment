use devenv_manager_tauri_lib::commands::homebrew;
use devenv_manager_tauri_lib::models::BrewServiceStatus;

#[test]
fn parse_services_all_status_states() {
    let output = "\
Name Status User File
redis started ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.redis.plist
postgresql stopped ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
mysql error ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.mysql.plist
dnsmasq none  
unbound weird_status ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.unbound.plist
";

    let services = homebrew::parse_brew_services(output);
    assert_eq!(services.len(), 5);

    assert_eq!(services[0].name, "redis");
    assert_eq!(services[0].status, BrewServiceStatus::Started);

    assert_eq!(services[1].name, "postgresql");
    assert_eq!(services[1].status, BrewServiceStatus::Stopped);

    assert_eq!(services[2].name, "mysql");
    assert_eq!(services[2].status, BrewServiceStatus::Error);

    assert_eq!(services[3].name, "dnsmasq");
    assert_eq!(services[3].status, BrewServiceStatus::None);

    assert_eq!(services[4].name, "unbound");
    assert_eq!(services[4].status, BrewServiceStatus::Unknown);
}

#[test]
fn parse_services_with_exit_codes() {
    // Real `brew services list` format: exit_code only appears for "error" status
    // Format: NAME error EXIT_CODE USER FILE
    // Non-error: NAME started USER FILE (no exit code field)
    let output = "\
Name Status User File
redis started ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.redis.plist
mysql error 1 ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.mysql.plist
nginx error 256 ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.nginx.plist
";

    let services = homebrew::parse_brew_services(output);
    assert_eq!(services.len(), 3);

    // started services have no exit_code
    assert_eq!(services[0].exit_code, None);
    // error services have exit_code from the field immediately after "error"
    assert_eq!(services[1].exit_code, Some(1));
    assert_eq!(services[2].exit_code, Some(256));
}

#[test]
fn parse_services_user_and_file_fields() {
    let output = "\
Name Status User File
redis started ray /Users/ray/Library/LaunchAgents/homebrew.mxcl.redis.plist
postgresql stopped admin /opt/homebrew/plist/postgresql.plist
";

    let services = homebrew::parse_brew_services(output);
    assert_eq!(services.len(), 2);

    assert_eq!(services[0].user.as_deref(), Some("ray"));
    assert_eq!(
        services[0].file.as_deref(),
        Some("/Users/ray/Library/LaunchAgents/homebrew.mxcl.redis.plist")
    );

    assert_eq!(services[1].user.as_deref(), Some("admin"));
    assert_eq!(
        services[1].file.as_deref(),
        Some("/opt/homebrew/plist/postgresql.plist")
    );
}

#[test]
fn parse_empty_service_list() {
    let output = "Name Status User File\n";
    let services = homebrew::parse_brew_services(output);
    assert!(services.is_empty());
}

#[test]
fn parse_service_list_header_only_with_trailing_whitespace() {
    let output = "Name Status User File\n   \n  \n";
    let services = homebrew::parse_brew_services(output);
    assert!(services.is_empty());
}

#[test]
fn parse_service_with_minimal_columns() {
    // Only name and status — no user, file, or exit code
    let output = "\
Name Status
redis started
";

    let services = homebrew::parse_brew_services(output);
    assert_eq!(services.len(), 1);
    assert_eq!(services[0].name, "redis");
    assert_eq!(services[0].status, BrewServiceStatus::Started);
    assert!(services[0].user.is_none());
    assert!(services[0].file.is_none());
}

#[test]
fn from_raw_status_case_insensitive() {
    assert_eq!(BrewServiceStatus::from_raw("Started"), BrewServiceStatus::Started);
    assert_eq!(BrewServiceStatus::from_raw("STARTED"), BrewServiceStatus::Started);
    assert_eq!(BrewServiceStatus::from_raw("STOPPED"), BrewServiceStatus::Stopped);
    assert_eq!(BrewServiceStatus::from_raw("Error"), BrewServiceStatus::Error);
    assert_eq!(BrewServiceStatus::from_raw("NONE"), BrewServiceStatus::None);
    assert_eq!(BrewServiceStatus::from_raw("garbage"), BrewServiceStatus::Unknown);
    assert_eq!(BrewServiceStatus::from_raw(""), BrewServiceStatus::Unknown);
}
