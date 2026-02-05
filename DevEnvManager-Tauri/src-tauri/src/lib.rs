pub mod commands;
pub mod models;
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
            commands::homebrew::list_brew_services,
            commands::homebrew::start_service,
            commands::homebrew::stop_service,
            commands::homebrew::restart_service,
            commands::orbstack::list_containers,
            commands::orbstack::start_container,
            commands::orbstack::stop_container,
            commands::ports::list_active_ports
        ]);

    if let Err(error) = app.run(tauri::generate_context!()) {
        eprintln!("error while running tauri application: {error}");
    }
}
