use iced::widget::{button, checkbox, column, container, row, text};
use iced::{Element, Length};

use crate::app::Message;
use crate::config::AppConfig;

pub fn view(config: &AppConfig) -> Element<'_, Message> {
    let interval_label = format!("Refresh interval: {}s", config.refresh_interval_secs);
    let interval_buttons = row([
        button("30s").on_press(Message::SetRefreshInterval(30)).into(),
        button("60s").on_press(Message::SetRefreshInterval(60)).into(),
        button("300s").on_press(Message::SetRefreshInterval(300)).into(),
    ])
    .spacing(8);

    let content = column([
        text("Settings").size(18).into(),
        text(interval_label).into(),
        interval_buttons.into(),
        checkbox(config.launch_at_login)
            .label("Launch at login")
            .on_toggle(Message::ToggleLaunchAtLogin)
            .into(),
        checkbox(config.show_notifications)
            .label("Show notifications")
            .on_toggle(Message::ToggleShowNotifications)
            .into(),
    ])
    .spacing(12);

    container(content)
        .padding(16)
        .width(Length::Fill)
        .height(Length::Fill)
        .into()
}
