use iced::widget::{row, text};
use iced::Element;

use crate::app::Message;
use crate::models::Container;

pub fn view(container: &Container) -> Element<'_, Message> {
    let name = text(&container.name).size(14);
    let status = text(container.display_status()).size(12);

    row([name.into(), status.into()])
        .spacing(12)
        .into()
}
