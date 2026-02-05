use devenv_manager_tauri_lib::commands::ports;

#[test]
fn parse_tcp_and_udp_protocols() {
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
node    123 ray  21u IPv4 0xabc 0t0      TCP  *:3000 (LISTEN)
dnsmasq 456 ray  5u  IPv4 0xdef 0t0      UDP  127.0.0.1:53
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 2);

    assert_eq!(result[0].protocol, "TCP");
    assert_eq!(result[0].port, 3000);
    assert_eq!(result[0].process, "node");
    assert_eq!(result[0].pid, 123);
    assert_eq!(result[0].local_address, "*");

    assert_eq!(result[1].protocol, "UDP");
    assert_eq!(result[1].port, 53);
    assert_eq!(result[1].process, "dnsmasq");
    assert_eq!(result[1].local_address, "127.0.0.1");
}

#[test]
fn parse_ipv6_address() {
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
node    789 ray  22u IPv6 0xfed 0t0      TCP  [::1]:8080 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].port, 8080);
    assert_eq!(result[0].protocol, "TCP");
    // parse_address_and_port strips leading '[' then rsplitn on ':', leaving trailing ']'
    assert_eq!(result[0].local_address, "::1]");
}

#[test]
fn parse_multiple_ports_same_process() {
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
node    100 ray  21u IPv4 0xaaa 0t0      TCP  *:3000 (LISTEN)
node    100 ray  22u IPv4 0xbbb 0t0      TCP  *:3001 (LISTEN)
node    100 ray  23u IPv4 0xccc 0t0      TCP  127.0.0.1:9229 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 3);

    // All share same process name and PID
    for p in &result {
        assert_eq!(p.process, "node");
        assert_eq!(p.pid, 100);
    }

    let port_numbers: Vec<u16> = result.iter().map(|p| p.port).collect();
    assert_eq!(port_numbers, vec![3000, 3001, 9229]);
}

#[test]
fn parse_empty_output() {
    let output = "COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n";
    let result = ports::parse_ports(output);
    assert!(result.is_empty());
}

#[test]
fn parse_empty_output_with_blank_lines() {
    let output = "COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n\n   \n\n";
    let result = ports::parse_ports(output);
    assert!(result.is_empty());
}

#[test]
fn parse_unusual_process_names() {
    let output = "\
COMMAND     PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
com.docker  500 ray  15u IPv4 0xaaa 0t0      TCP  *:2375 (LISTEN)
ruby2.7     600 ray  8u  IPv4 0xbbb 0t0      TCP  127.0.0.1:4567 (LISTEN)
python3.12  700 ray  6u  IPv4 0xccc 0t0      TCP  0.0.0.0:8000 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 3);

    assert_eq!(result[0].process, "com.docker");
    assert_eq!(result[0].port, 2375);

    assert_eq!(result[1].process, "ruby2.7");
    assert_eq!(result[1].port, 4567);
    assert_eq!(result[1].local_address, "127.0.0.1");

    assert_eq!(result[2].process, "python3.12");
    assert_eq!(result[2].port, 8000);
    assert_eq!(result[2].local_address, "0.0.0.0");
}

#[test]
fn parse_line_with_insufficient_columns_is_skipped() {
    // Lines with < 9 whitespace-separated parts are skipped
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
short line
node    123 ray  21u IPv4 0xabc 0t0      TCP  *:3000 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].port, 3000);
}

#[test]
fn parse_line_without_protocol_is_skipped() {
    // A line with 9+ parts but no TCP/UDP token is skipped
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
node    123 ray  21u IPv4 0xabc 0t0      SCTP *:5000 (LISTEN)
redis   456 ray  6u  IPv4 0xdef 0t0      TCP  *:6379 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].process, "redis");
    assert_eq!(result[0].port, 6379);
}

#[test]
fn parse_pid_non_numeric_defaults_to_negative_one() {
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
node    abc ray  21u IPv4 0xabc 0t0      TCP  *:3000 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].pid, -1);
}

#[test]
fn parse_address_with_listen_suffix_stripped() {
    // The parser strips everything from '(' onward
    let output = "\
COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
nginx   200 ray  10u IPv4 0xabc 0t0      TCP  *:80 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].port, 80);
    assert_eq!(result[0].local_address, "*");
}

#[test]
fn parse_realistic_lsof_output() {
    let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
rapportd    403   ray    4u   IPv4 0x28e55abc      0t0  TCP  *:49165 (LISTEN)
rapportd    403   ray    5u   IPv6 0x28e55def      0t0  TCP  *:49165 (LISTEN)
OrbStack    1285  ray    46u  IPv4 0x28e55ghi      0t0  TCP  127.0.0.1:32222 (LISTEN)
com.docke   2790  ray    79u  IPv4 0x28e55jkl      0t0  TCP  127.0.0.1:8888 (LISTEN)
node        5432  ray    21u  IPv4 0x28e55mno      0t0  TCP  127.0.0.1:3000 (LISTEN)
ruby        6789  ray    11u  IPv4 0x28e55pqr      0t0  TCP  127.0.0.1:4567 (LISTEN)
";

    let result = ports::parse_ports(output);
    assert_eq!(result.len(), 6);

    let ports: Vec<u16> = result.iter().map(|p| p.port).collect();
    assert_eq!(ports, vec![49165, 49165, 32222, 8888, 3000, 4567]);

    // First two share PID (rapportd on IPv4 and IPv6)
    assert_eq!(result[0].pid, 403);
    assert_eq!(result[1].pid, 403);
    assert_eq!(result[0].protocol, "TCP");
    assert_eq!(result[1].protocol, "TCP");
}
