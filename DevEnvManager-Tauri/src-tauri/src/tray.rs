use std::fs;
use std::path::PathBuf;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tauri::image::Image;
use tauri::menu::{MenuBuilder, MenuItem};
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_positioner::{Position, WindowExt};

fn load_tray_icon() -> tauri::Result<Image<'static>> {
    // Use the new distinctive tray icon (terminal prompt with chevron)
    // This is a macOS template icon (black on transparent) that will
    // automatically invert for light/dark mode
    let icon_bytes = include_bytes!("../icons/tray-icon.png");
    match Image::from_bytes(icon_bytes) {
        Ok(icon) => Ok(icon),
        Err(_) => {
            // Fallback: create a simple placeholder
            let size = 22u32;
            let rgba = vec![255u8; (size * size * 4) as usize];
            Ok(Image::new_owned(rgba, size, size))
        }
    }
}

fn toggle_main_window(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.as_ref().window().move_window(Position::TrayCenter);
        let is_visible = window.is_visible().unwrap_or(false);
        if is_visible {
            let _ = window.hide();
        } else {
            let _ = window.show();
            let _ = window.set_focus();
        }
    }
}

pub fn create(app: &AppHandle) -> tauri::Result<()> {
    let icon = load_tray_icon()?;
    let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let settings = MenuItem::with_id(app, "settings", "Settings", true, None::<&str>)?;
    let menu = MenuBuilder::new(app)
        .item(&settings)
        .separator()
        .item(&quit)
        .build()?;

    TrayIconBuilder::with_id("main")
        .icon(icon)
        .icon_as_template(true)
        .tooltip("DevEnvManager (Tauri)")
        .title("T")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id().as_ref() {
            "quit" => app.exit(0),
            "settings" => {
                let _ = app.emit("open-settings", ());
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            let app = tray.app_handle();
            tauri_plugin_positioner::on_tray_event(app, &event);
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                toggle_main_window(app);
            }
        })
        .build(app)?;

    start_status_writer("DevEnvManager (Tauri)");

    Ok(())
}

fn start_status_writer(label: &str) {
    let label = label.to_string();
    thread::spawn(move || loop {
        write_visibility_status(&label);
        thread::sleep(Duration::from_secs(30));
    });
}

fn write_visibility_status(label: &str) {
    let home = match std::env::var("HOME") {
        Ok(value) => value,
        Err(_) => return,
    };

    let dir = PathBuf::from(home)
        .join(".config")
        .join("dev-env")
        .join("menubar");

    let _ = fs::create_dir_all(&dir);

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|value| value.as_secs())
        .unwrap_or(0);

    let payload = format!(
        "{{\"app\":\"tauri\",\"label\":\"{}\",\"updated_at_epoch\":{}}}",
        label, timestamp
    );

    let _ = fs::write(dir.join("tauri.json"), payload);
}
