use std::collections::BTreeMap;
use std::time::Duration;

use iced::{window, Element, Point, Size, Subscription, Task, Theme};
use tray_icon::{MouseButton, MouseButtonState, TrayIconEvent};
use tray_icon::menu::dpi::PhysicalPosition;

use crate::{config::AppConfig, domain, models, views};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WindowKind {
    Popup,
    Settings,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PopupTab {
    Tools,
    Services,
    Containers,
}

#[derive(Debug)]
pub struct App {
    windows: BTreeMap<window::Id, WindowKind>,
    tools: Vec<models::Tool>,
    services: Vec<models::Service>,
    containers: Vec<models::Container>,
    config: AppConfig,
    active_tab: PopupTab,
}

#[derive(Debug, Clone)]
pub enum Message {
    PollTray,
    WindowOpened(window::Id),
    WindowClosed(window::Id),
    ToolsLoaded(Vec<models::Tool>),
    ServicesLoaded(Vec<models::Service>),
    ContainersLoaded(Vec<models::Container>),
    InstallTool(String),
    UpdateTool(String),
    StartService(String),
    StopService(String),
    OpenSettings,
    RefreshAll,
    Tick,
    SelectTab(PopupTab),
    SetRefreshInterval(u64),
    ToggleLaunchAtLogin(bool),
    ToggleShowNotifications(bool),
}

impl App {
    pub fn new() -> (Self, Task<Message>) {
        let config = AppConfig::load();
        let app = Self {
            windows: BTreeMap::new(),
            tools: Vec::new(),
            services: Vec::new(),
            containers: Vec::new(),
            config,
            active_tab: PopupTab::Tools,
        };

        (app, Self::refresh_task())
    }

    pub fn title(&self, window_id: window::Id) -> String {
        match self.windows.get(&window_id) {
            Some(WindowKind::Popup) => "DevEnvManager".to_string(),
            Some(WindowKind::Settings) => "DevEnvManager Settings".to_string(),
            None => "DevEnvManager".to_string(),
        }
    }

    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::PollTray => self.handle_tray_events(),
            Message::WindowOpened(_) => Task::none(),
            Message::WindowClosed(id) => {
                self.windows.remove(&id);
                Task::none()
            }
            Message::ToolsLoaded(tools) => {
                self.tools = tools;
                Task::none()
            }
            Message::ServicesLoaded(services) => {
                self.services = services;
                Task::none()
            }
            Message::ContainersLoaded(containers) => {
                self.containers = containers;
                Task::none()
            }
            Message::InstallTool(name) => {
                Task::perform(domain::mise::install_tool(name), |_| Message::RefreshAll)
            }
            Message::UpdateTool(name) => {
                Task::perform(domain::mise::update_tool(name), |_| Message::RefreshAll)
            }
            Message::StartService(name) => {
                Task::perform(domain::homebrew::start_service(name), |_| Message::RefreshAll)
            }
            Message::StopService(name) => {
                Task::perform(domain::homebrew::stop_service(name), |_| Message::RefreshAll)
            }
            Message::OpenSettings => self.open_settings_window(),
            Message::RefreshAll => Self::refresh_task(),
            Message::Tick => Self::refresh_task(),
            Message::SelectTab(tab) => {
                self.active_tab = tab;
                Task::none()
            }
            Message::SetRefreshInterval(value) => {
                self.config.refresh_interval_secs = value;
                self.persist_config();
                Task::none()
            }
            Message::ToggleLaunchAtLogin(value) => {
                self.config.launch_at_login = value;
                self.persist_config();
                Task::none()
            }
            Message::ToggleShowNotifications(value) => {
                self.config.show_notifications = value;
                self.persist_config();
                Task::none()
            }
        }
    }

    pub fn view(&self, window_id: window::Id) -> Element<'_, Message> {
        match self.windows.get(&window_id) {
            Some(WindowKind::Popup) => views::popup::view(
                &self.tools,
                &self.services,
                &self.containers,
                self.active_tab,
            ),
            Some(WindowKind::Settings) => views::settings::view(&self.config),
            None => views::popup::empty_view(),
        }
    }

    pub fn subscription(&self) -> Subscription<Message> {
        Subscription::batch([
            iced::time::every(Duration::from_millis(50)).map(|_| Message::PollTray),
            iced::time::every(Duration::from_secs(self.config.refresh_interval_secs))
                .map(|_| Message::Tick),
        ])
    }

    pub fn theme(&self, _window: window::Id) -> Option<Theme> {
        Some(Theme::Light)
    }

    fn refresh_task() -> Task<Message> {
        Task::batch([
            Task::perform(domain::mise::list_tools(), Message::ToolsLoaded),
            Task::perform(domain::homebrew::list_services(), Message::ServicesLoaded),
            Task::perform(domain::orbstack::list_containers(), Message::ContainersLoaded),
        ])
    }

    fn handle_tray_events(&mut self) -> Task<Message> {
        let mut task = Task::none();

        while let Ok(event) = TrayIconEvent::receiver().try_recv() {
            match event {
                TrayIconEvent::Click {
                    position,
                    button,
                    button_state,
                    ..
                } => {
                    if button == MouseButton::Left && button_state == MouseButtonState::Up {
                        task = self.toggle_popup(position);
                    }
                }
                _ => {}
            }
        }

        task
    }

    fn toggle_popup(&mut self, position: PhysicalPosition<f64>) -> Task<Message> {
        if let Some(popup_id) = self.window_id(WindowKind::Popup) {
            self.windows.remove(&popup_id);
            return window::close::<Message>(popup_id).map(move |_| Message::WindowClosed(popup_id));
        }

        let settings = window::Settings {
            size: Size::new(420.0, 540.0),
            position: window::Position::Specific(Point::new(
                position.x as f32 - 210.0,
                position.y as f32 + 8.0,
            )),
            decorations: false,
            resizable: false,
            level: window::Level::AlwaysOnTop,
            ..Default::default()
        };

        let (id, open_task) = window::open(settings);
        self.windows.insert(id, WindowKind::Popup);
        open_task.map(Message::WindowOpened)
    }

    fn open_settings_window(&mut self) -> Task<Message> {
        if self.window_id(WindowKind::Settings).is_some() {
            return Task::none();
        }

        let settings = window::Settings {
            size: Size::new(360.0, 320.0),
            decorations: true,
            resizable: false,
            ..Default::default()
        };

        let (id, open_task) = window::open(settings);
        self.windows.insert(id, WindowKind::Settings);
        open_task.map(Message::WindowOpened)
    }

    fn window_id(&self, kind: WindowKind) -> Option<window::Id> {
        self.windows
            .iter()
            .find_map(|(id, window_kind)| if *window_kind == kind { Some(*id) } else { None })
    }

    fn persist_config(&self) {
        if let Err(error) = self.config.save() {
            eprintln!("Failed to save config: {error}");
        }
    }
}
