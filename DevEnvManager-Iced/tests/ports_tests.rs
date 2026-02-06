#[cfg(test)]
mod tests {
    use devenv_manager_iced::domain::ports::parse_ports_output;

    #[test]
    fn parses_multiple_ports() {
        let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node      12345   test   21u  IPv4 0x1234567890      0t0  TCP *:3000 (LISTEN)
redis-ser 67890   test   6u   IPv4 0x0987654321      0t0  TCP 127.0.0.1:6379 (LISTEN)
postgres  11111   test   5u   IPv4 0x1111111111      0t0  TCP 127.0.0.1:5432 (LISTEN)
";

        let ports = parse_ports_output(output);
        assert_eq!(ports.len(), 3);

        let node_port = ports.iter().find(|p| p.process == "node").expect("node port");
        assert_eq!(node_port.port, 3000);
        assert_eq!(node_port.pid, 12345);
        assert_eq!(node_port.address, "*");

        let redis_port = ports.iter().find(|p| p.process == "redis-ser").expect("redis port");
        assert_eq!(redis_port.port, 6379);
        assert_eq!(redis_port.pid, 67890);
        assert_eq!(redis_port.address, "127.0.0.1");

        let pg_port = ports.iter().find(|p| p.process == "postgres").expect("postgres port");
        assert_eq!(pg_port.port, 5432);
        assert_eq!(pg_port.pid, 11111);
    }

    #[test]
    fn parses_empty_output() {
        let ports = parse_ports_output("");
        assert!(ports.is_empty());
    }

    #[test]
    fn parses_header_only() {
        let output = "COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME\n";
        let ports = parse_ports_output(output);
        assert!(ports.is_empty());
    }

    #[test]
    fn parses_various_process_names() {
        let output = "\
COMMAND         PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
httpd         22222   root   4u   IPv4 0xaaa            0t0  TCP *:80 (LISTEN)
com.docker.b  33333   test   17u  IPv4 0xbbb            0t0  TCP *:8080 (LISTEN)
Python        44444   test   3u   IPv4 0xccc            0t0  TCP 127.0.0.1:8000 (LISTEN)
";

        let ports = parse_ports_output(output);
        assert_eq!(ports.len(), 3);

        assert!(ports.iter().any(|p| p.process == "httpd" && p.port == 80));
        assert!(ports.iter().any(|p| p.process == "com.docker.b" && p.port == 8080));
        assert!(ports.iter().any(|p| p.process == "Python" && p.port == 8000));
    }

    #[test]
    fn parses_ipv6_addresses() {
        let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node      12345   test   21u  IPv6 0x1234567890      0t0  TCP [::1]:3000 (LISTEN)
nginx     67890   test   6u   IPv6 0x0987654321      0t0  TCP [::]:8080 (LISTEN)
";

        let ports = parse_ports_output(output);
        assert_eq!(ports.len(), 2);

        let node_port = ports.iter().find(|p| p.process == "node").expect("node port");
        assert_eq!(node_port.port, 3000);
        assert_eq!(node_port.address, "[::1]");

        let nginx_port = ports.iter().find(|p| p.process == "nginx").expect("nginx port");
        assert_eq!(nginx_port.port, 8080);
        assert_eq!(nginx_port.address, "[::]");
    }

    #[test]
    fn skips_lines_with_fewer_than_nine_parts() {
        let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node      12345   test   21u  IPv4 0x1234567890      0t0  TCP *:3000 (LISTEN)
short     99
";

        let ports = parse_ports_output(output);
        assert_eq!(ports.len(), 1);
        assert_eq!(ports[0].process, "node");
    }

    #[test]
    fn returns_duplicate_ports_for_same_port_different_processes() {
        let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node      12345   test   21u  IPv4 0x1234567890      0t0  TCP *:3000 (LISTEN)
node      12345   test   22u  IPv6 0x0987654321      0t0  TCP [::1]:3000 (LISTEN)
";

        let ports = parse_ports_output(output);
        // Both entries are returned (no deduplication in parse_ports_output)
        assert_eq!(ports.len(), 2);
        assert!(ports.iter().all(|p| p.port == 3000));
    }

    #[test]
    fn skips_lines_without_colon_in_address() {
        let output = "\
COMMAND     PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node      12345   test   21u  IPv4 0x1234567890      0t0  TCP noport (LISTEN)
redis     67890   test   6u   IPv4 0x0987654321      0t0  TCP 127.0.0.1:6379 (LISTEN)
";

        let ports = parse_ports_output(output);
        // The "noport" line has no colon, so rsplit_once(':') returns None → skipped
        assert_eq!(ports.len(), 1);
        assert_eq!(ports[0].process, "redis");
    }
}
