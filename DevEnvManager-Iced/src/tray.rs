use std::error::Error;

use std::fs;
use std::path::PathBuf;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tray_icon::menu::Menu;
use tray_icon::{Icon, TrayIcon, TrayIconBuilder};

pub fn create_tray_icon() -> Result<TrayIcon, Box<dyn Error>> {
    let icon = load_icon()?;
    let menu = Menu::new();

    let tray = TrayIconBuilder::new()
        .with_icon(icon)
        .with_tooltip("DevEnvManager (Iced)")
        .with_title("I")
        .with_icon_as_template(true)
        .with_menu(Box::new(menu))
        .with_menu_on_left_click(false)
        .build()?;

    start_status_writer("DevEnvManager (Iced)");

    Ok(tray)
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
        "{{\"app\":\"iced\",\"label\":\"{}\",\"updated_at_epoch\":{}}}",
        label, timestamp
    );

    let _ = fs::write(dir.join("iced.json"), payload);
}

fn load_icon() -> Result<Icon, Box<dyn Error>> {
    let bytes = include_bytes!("../icons/icon.png");

    match image::load_from_memory(bytes) {
        Ok(image) => {
            let rgba = image.into_rgba8();
            let (width, height) = rgba.dimensions();
            Ok(Icon::from_rgba(rgba.into_raw(), width, height)?)
        }
        Err(error) => {
            eprintln!("Failed to decode icon.png: {error}");
            let rgba = vec![0, 0, 0, 0];
            Ok(Icon::from_rgba(rgba, 1, 1)?)
        }
    }
}
