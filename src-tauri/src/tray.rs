use crate::settings::ThemeId;
use crate::{AppState, HaloState};
use tauri::{
    menu::{CheckMenuItem, CheckMenuItemBuilder, MenuBuilder, MenuItemBuilder, SubmenuBuilder},
    tray::TrayIconBuilder,
    AppHandle, Emitter, Manager,
};
use tauri_plugin_autostart::ManagerExt;

#[derive(Clone)]
struct ThemeItems {
    cyber: CheckMenuItem<tauri::Wry>,
    sakura: CheckMenuItem<tauri::Wry>,
    minimal: CheckMenuItem<tauri::Wry>,
}

impl ThemeItems {
    fn set_selected(&self, theme: ThemeId) {
        let _ = self.cyber.set_checked(theme == ThemeId::CyberBlue);
        let _ = self.sakura.set_checked(theme == ThemeId::Sakura);
        let _ = self.minimal.set_checked(theme == ThemeId::Minimal);
    }
}

pub fn create_tray(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let initial = app
        .state::<AppState>()
        .settings
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .clone();
    let actual_autostart = app
        .autolaunch()
        .is_enabled()
        .unwrap_or(initial.start_at_login);
    if actual_autostart != initial.start_at_login {
        let state = app.state::<AppState>();
        let mut settings = state
            .settings
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        settings.start_at_login = actual_autostart;
        let _ = settings.save();
    }

    let title = MenuItemBuilder::with_id("title", "Codex Halo")
        .enabled(false)
        .build(app)?;
    let enable = CheckMenuItemBuilder::new("Enable Halo")
        .id("enable")
        .checked(initial.enabled)
        .build(app)?;
    let cyber = CheckMenuItemBuilder::new("Cyber Blue")
        .id("theme_cyber_blue")
        .checked(initial.theme == ThemeId::CyberBlue)
        .build(app)?;
    let sakura = CheckMenuItemBuilder::new("Sakura")
        .id("theme_sakura")
        .checked(initial.theme == ThemeId::Sakura)
        .build(app)?;
    let minimal = CheckMenuItemBuilder::new("Minimal")
        .id("theme_minimal")
        .checked(initial.theme == ThemeId::Minimal)
        .build(app)?;
    let theme_items = ThemeItems {
        cyber: cyber.clone(),
        sakura: sakura.clone(),
        minimal: minimal.clone(),
    };
    let themes = SubmenuBuilder::new(app, "Theme")
        .item(&cyber)
        .item(&sakura)
        .item(&minimal)
        .build()?;
    let demo = MenuItemBuilder::with_id("demo", "Demo Mode").build(app)?;
    let autostart = CheckMenuItemBuilder::new("Start at Login")
        .id("autostart")
        .checked(actual_autostart)
        .build(app)?;
    let logs = MenuItemBuilder::with_id("logs", "Open Logs").build(app)?;
    let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)?;

    let menu = MenuBuilder::new(app)
        .item(&title)
        .separator()
        .item(&enable)
        .item(&themes)
        .item(&demo)
        .item(&autostart)
        .separator()
        .item(&logs)
        .item(&quit)
        .build()?;

    let enable_for_handler = enable.clone();
    let autostart_for_handler = autostart.clone();
    let themes_for_handler = theme_items.clone();
    TrayIconBuilder::with_id("main")
        .icon(
            app.default_window_icon()
                .cloned()
                .ok_or("App icon missing")?,
        )
        .icon_as_template(true)
        .tooltip("Codex Halo")
        .menu(&menu)
        .show_menu_on_left_click(true)
        .on_menu_event(move |app, event| match event.id().as_ref() {
            "enable" => toggle_enabled(app, &enable_for_handler),
            "theme_cyber_blue" => {
                set_theme(app, ThemeId::CyberBlue, &themes_for_handler);
            }
            "theme_sakura" => set_theme(app, ThemeId::Sakura, &themes_for_handler),
            "theme_minimal" => set_theme(app, ThemeId::Minimal, &themes_for_handler),
            "demo" => {
                if let Err(error) = crate::run_demo(app.clone()) {
                    log::info!("Demo Mode not started: {error}");
                }
            }
            "autostart" => toggle_autostart(app, &autostart_for_handler),
            "logs" => {
                if let Err(error) = crate::platform::open_log_dir() {
                    log::warn!("Could not open logs: {error}");
                }
            }
            "quit" => {
                crate::render_state(app, HaloState::Idle);
                app.exit(0);
            }
            other => log::warn!("Unknown tray menu event: {other}"),
        })
        .build(app)?;

    log::info!("System tray ready");
    Ok(())
}

fn toggle_enabled(app: &AppHandle, item: &CheckMenuItem<tauri::Wry>) {
    let state = app.state::<AppState>();
    let enabled = {
        let mut settings = state
            .settings
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        settings.enabled = !settings.enabled;
        if let Err(error) = settings.save() {
            log::warn!("Could not save Enable Halo setting: {error}");
        }
        settings.enabled
    };
    let _ = item.set_checked(enabled);
    if enabled {
        crate::restore_latest_state(app);
    } else {
        crate::apply_state(
            app,
            &state.current,
            &state.timeout_tx,
            HaloState::Idle,
            None,
        );
    }
    log::info!("Enable Halo: {enabled}");
}

fn set_theme(app: &AppHandle, theme: ThemeId, items: &ThemeItems) {
    let state = app.state::<AppState>();
    {
        let mut settings = state
            .settings
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        settings.theme = theme;
        if let Err(error) = settings.save() {
            log::warn!("Could not save theme: {error}");
        }
    }
    items.set_selected(theme);
    let _ = app.emit(
        "halo-theme",
        serde_json::json!({ "theme": theme.to_string() }),
    );
    log::info!("Theme: {theme}");
}

fn toggle_autostart(app: &AppHandle, item: &CheckMenuItem<tauri::Wry>) {
    let current = app.autolaunch().is_enabled().unwrap_or(false);
    let desired = !current;
    let result = if desired {
        app.autolaunch().enable()
    } else {
        app.autolaunch().disable()
    };
    match result {
        Ok(()) => {
            let state = app.state::<AppState>();
            let mut settings = state
                .settings
                .lock()
                .unwrap_or_else(|poisoned| poisoned.into_inner());
            settings.start_at_login = desired;
            if let Err(error) = settings.save() {
                log::warn!("Could not save autostart setting: {error}");
            }
            let _ = item.set_checked(desired);
            log::info!("Start at Login: {desired}");
        }
        Err(error) => {
            let _ = item.set_checked(current);
            log::warn!("Could not change Start at Login: {error}");
        }
    }
}
