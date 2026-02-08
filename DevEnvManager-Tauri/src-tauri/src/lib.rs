pub mod commands;
pub mod models;
pub mod telemetry;
mod tray;

use tauri::Manager;

pub use commands::*;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app = tauri::Builder::default()
        .plugin(tauri_plugin_positioner::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_single_instance::init(|app, _, _| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.show();
                let _ = window.set_focus();
            }
        }))
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .setup(|app| {
            tray::create(app.handle())?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::mise::list_mise_tools,
            commands::mise::install_tool,
            commands::mise::update_tool,
            commands::mise::mise_doctor,
            commands::mise::run_mise_validate,
            commands::mise::run_mise_doctor,
            commands::mise::run_mise_update_all,
            commands::mise::run_mise_dashboard,
            commands::homebrew::list_brew_services,
            commands::homebrew::start_service,
            commands::homebrew::stop_service,
            commands::homebrew::restart_service,
            commands::orbstack::list_containers,
            commands::orbstack::start_container,
            commands::orbstack::stop_container,
            commands::orbstack::restart_container,
            commands::orbstack::shell_container,
            commands::orbstack::logs_container,
            commands::ports::list_active_ports,
            commands::ports::kill_port,
            commands::package_managers::get_package_managers_status,
            commands::package_managers::update_package_manager,
            commands::cloud::get_skypilot_status,
            commands::cloud::get_aws_status,
            commands::cloud::launch_skypilot_agent,
            commands::cloud::stop_skypilot_agents,
            commands::cloud::list_skypilot_clusters,
            commands::cloud::stop_skypilot_cluster,
            commands::cloud::ssh_skypilot_cluster,
            commands::cloud::get_skypilot_logs
        ]);

    if let Err(error) = app.run(tauri::generate_context!()) {
        eprintln!("error while running tauri application: {error}");
    }
}
