use devenv_manager_iced::{app, tray};

fn main() -> iced::Result {
    if let Err(error) = tray::create_tray_icon() {
        eprintln!("Failed to create tray icon: {error}");
    }

    iced::daemon(app::App::new, app::App::update, app::App::view)
        .title(app::App::title)
        .subscription(app::App::subscription)
        .theme(app::App::theme)
        .run()
}
