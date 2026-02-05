use iced::widget::{button, row, text};
use iced::Element;

use crate::app::Message;
use crate::models::Tool;

pub fn view(tool: &Tool) -> Element<'_, Message> {
    let name = text(tool.display_name()).size(14);
    let version = text(tool.display_version()).size(12);
    let status = text(tool.status().display_name()).size(12);

    let action = if tool.installed {
        button(text("Update")).on_press(Message::UpdateTool(tool.name.clone()))
    } else {
        button(text("Install")).on_press(Message::InstallTool(tool.name.clone()))
    };

    row([
        name.into(),
        version.into(),
        status.into(),
        action.into(),
    ])
    .spacing(12)
    .into()
}
