use std::error::Error;

use tray_icon::{Icon, TrayIcon, TrayIconBuilder};
use tray_icon::menu::Menu;

pub fn create_tray_icon() -> Result<TrayIcon, Box<dyn Error>> {
    let icon = load_icon()?;
    let menu = Menu::new();

    let tray = TrayIconBuilder::new()
        .with_icon(icon)
        .with_tooltip("DevEnvManager")
        .with_icon_as_template(true)
        .with_menu(Box::new(menu))
        .with_menu_on_left_click(false)
        .build()?;

    Ok(tray)
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
