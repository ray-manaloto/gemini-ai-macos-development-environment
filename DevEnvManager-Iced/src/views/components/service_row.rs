use iced::widget::{button, row, text};
use iced::Element;

use crate::app::Message;
use crate::models::{Service, ServiceStatus};

pub fn view(service: &Service) -> Element<'_, Message> {
    let name = text(service.display_name()).size(14);
    let status = text(service.status.display_name()).size(12);

    let action = match service.status {
        ServiceStatus::Started => {
            button(text("Stop")).on_press(Message::StopService(service.name.clone()))
        }
        ServiceStatus::Stopped | ServiceStatus::None | ServiceStatus::Error | ServiceStatus::Unknown => {
            button(text("Start")).on_press(Message::StartService(service.name.clone()))
        }
    };

    row([name.into(), status.into(), action.into()])
        .spacing(12)
        .into()
}
