use devenv_manager_iced::{app, tray};

fn main() -> iced::Result {
    tray::create_tray_icon()
        .expect("Failed to create tray icon — cannot run without menu bar presence");

    iced::daemon(app::App::new, app::App::update, app::App::view)
        .title(app::App::title)
        .subscription(app::App::subscription)
        .theme(app::App::theme)
        .run()
}
