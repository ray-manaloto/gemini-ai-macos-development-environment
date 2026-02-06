pub mod cloud;
pub mod homebrew;
pub mod mise;
pub mod orbstack;
pub mod package_managers;
pub mod ports;

use std::time::Duration;
use tokio::process::Command;
use tokio::time::timeout;

pub async fn run_command(program: &str, args: &[&str]) -> Result<String, String> {
    let output = timeout(
        Duration::from_secs(30),
        Command::new(program).args(args).output(),
    )
    .await
    .map_err(|_| format!("{program} timed out after 30s"))?
    .map_err(|error| format!("Failed to run {program}: {error}"))?;

    if !output.status.success() {
        let stderr = String::from_utf8(output.stderr)
            .unwrap_or_else(|_| "<non-utf8 stderr>".to_string());
        return Err(format!("{program} failed: {stderr}"));
    }

    String::from_utf8(output.stdout)
        .map_err(|error| format!("Invalid UTF-8 output from {program}: {error}"))
}
