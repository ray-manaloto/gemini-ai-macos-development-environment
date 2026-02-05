use iced::widget::{button, column, container, row, scrollable, text};
use iced::{Element, Length};

use crate::app::{Message, PopupTab};
use crate::models::{Container, Service, Tool};
use crate::views::components::{container_row, service_row, tool_row};

pub fn view<'a>(
    tools: &'a [Tool],
    services: &'a [Service],
    containers: &'a [Container],
    active_tab: PopupTab,
) -> Element<'a, Message> {
    let header = row([
        text("DevEnvManager").size(18).into(),
        button(text("Refresh")).on_press(Message::RefreshAll).into(),
        button(text("Settings")).on_press(Message::OpenSettings).into(),
    ])
    .spacing(12);

    let tabs = row([
        tab_button("Tools", PopupTab::Tools, active_tab),
        tab_button("Services", PopupTab::Services, active_tab),
        tab_button("Containers", PopupTab::Containers, active_tab),
    ])
    .spacing(8);

    let content = match active_tab {
        PopupTab::Tools => list_tools(tools),
        PopupTab::Services => list_services(services),
        PopupTab::Containers => list_containers(containers),
    };

    container(
        column([header.into(), tabs.into(), content])
            .spacing(16)
            .width(Length::Fill),
    )
    .padding(16)
    .width(Length::Fill)
    .height(Length::Fill)
    .into()
}

pub fn empty_view() -> Element<'static, Message> {
    container(text(""))
        .width(Length::Fill)
        .height(Length::Fill)
        .into()
}

fn tab_button<'a>(label: &str, tab: PopupTab, active_tab: PopupTab) -> Element<'a, Message> {
    let title = if tab == active_tab {
        format!("[{label}]")
    } else {
        label.to_string()
    };

    button(text(title))
        .on_press(Message::SelectTab(tab))
        .into()
}

fn list_tools<'a>(tools: &'a [Tool]) -> Element<'a, Message> {
    if tools.is_empty() {
        return text("No tools found").into();
    }

    let mut children = Vec::new();
    for tool in tools {
        children.push(tool_row::view(tool));
    }

    let content = column(children).spacing(8);

    scrollable(content).height(Length::Fill).into()
}

fn list_services<'a>(services: &'a [Service]) -> Element<'a, Message> {
    if services.is_empty() {
        return text("No services found").into();
    }

    let mut children = Vec::new();
    for service in services {
        children.push(service_row::view(service));
    }

    let content = column(children).spacing(8);

    scrollable(content).height(Length::Fill).into()
}

fn list_containers<'a>(containers: &'a [Container]) -> Element<'a, Message> {
    if containers.is_empty() {
        return text("No containers found").into();
    }

    let mut children = Vec::new();
    for container in containers {
        children.push(container_row::view(container));
    }

    let content = column(children).spacing(8);

    scrollable(content).height(Length::Fill).into()
}
