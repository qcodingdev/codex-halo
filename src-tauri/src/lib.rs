mod logging;
mod platform;
mod settings;
mod state;
mod tray;
mod watcher;

use settings::AppSettings;
use state::{unix_time_ms, HaloEvent, HaloState};
use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{mpsc, Arc, Mutex};
use std::time::{Duration, Instant};
use tauri::{
    AppHandle, Emitter, Manager, Monitor, WebviewUrl, WebviewWindow, WebviewWindowBuilder,
};
use tauri_plugin_notification::NotificationExt;

const OVERLAY_PREFIX: &str = "overlay-";

#[derive(Debug)]
pub struct RuntimeState {
    pub state: HaloState,
    pub revision: u64,
}

#[derive(Debug, Clone, Copy)]
struct TimeoutSchedule {
    revision: u64,
    delay: Option<Duration>,
}

pub struct AppState {
    pub current: Arc<Mutex<RuntimeState>>,
    pub settings: Arc<Mutex<AppSettings>>,
    pub demo_mode: Arc<AtomicBool>,
    timeout_tx: mpsc::Sender<TimeoutSchedule>,
}

fn create_overlay(
    app: &AppHandle,
    label: String,
    monitor: &Monitor,
) -> Result<WebviewWindow, String> {
    let scale = monitor.scale_factor();
    let logical_size = monitor.size().to_logical::<f64>(scale);
    let logical_position = monitor.position().to_logical::<f64>(scale);

    let window = WebviewWindowBuilder::new(app, label, WebviewUrl::App("index.html".into()))
        .title("Codex Halo")
        .decorations(false)
        .transparent(true)
        .always_on_top(true)
        .visible_on_all_workspaces(true)
        .skip_taskbar(true)
        .visible(false)
        .resizable(false)
        .maximizable(false)
        .minimizable(false)
        .closable(false)
        .focused(false)
        .focusable(false)
        .shadow(false)
        .inner_size(logical_size.width, logical_size.height)
        .position(logical_position.x, logical_position.y)
        .build()
        .map_err(|error| error.to_string())?;
    window
        .set_ignore_cursor_events(true)
        .map_err(|error| error.to_string())?;
    Ok(window)
}

fn fit_monitor(window: &WebviewWindow, monitor: &Monitor) {
    if let Err(error) = window.set_position(tauri::Position::Physical(*monitor.position())) {
        log::warn!("Could not position overlay: {error}");
    }
    if let Err(error) = window.set_size(tauri::Size::Physical(*monitor.size())) {
        log::warn!("Could not size overlay: {error}");
    }
}

fn sync_overlays(app: &AppHandle) -> Result<Vec<WebviewWindow>, String> {
    let mut monitors = app
        .available_monitors()
        .map_err(|error| error.to_string())?;
    monitors.sort_by_key(|monitor| {
        (
            monitor.position().x,
            monitor.position().y,
            monitor.size().width,
            monitor.size().height,
        )
    });
    if monitors.is_empty() {
        return Err("No display is available".to_owned());
    }

    let mut expected = HashSet::with_capacity(monitors.len());
    let mut windows = Vec::with_capacity(monitors.len());
    for (index, monitor) in monitors.iter().enumerate() {
        let label = format!("{OVERLAY_PREFIX}{index}");
        expected.insert(label.clone());
        let window = match app.get_webview_window(&label) {
            Some(window) => window,
            None => {
                let window = create_overlay(app, label.clone(), monitor)?;
                log::info!(
                    "Created overlay {label} for display {}x{} at {},{}",
                    monitor.size().width,
                    monitor.size().height,
                    monitor.position().x,
                    monitor.position().y
                );
                window
            }
        };
        fit_monitor(&window, monitor);
        windows.push(window);
    }

    for (label, window) in app.webview_windows() {
        if label.starts_with(OVERLAY_PREFIX) && !expected.contains(&label) {
            if let Err(error) = window.destroy() {
                log::warn!("Could not remove stale overlay {label}: {error}");
            } else {
                log::info!("Removed stale overlay {label}");
            }
        }
    }
    Ok(windows)
}

fn render_state(app: &AppHandle, state: HaloState) {
    let windows = match sync_overlays(app) {
        Ok(windows) => windows,
        Err(error) => {
            log::error!("Could not synchronize overlay windows: {error}");
            return;
        }
    };

    if state == HaloState::Idle {
        let payload = serde_json::json!({ "state": state.to_string() });
        for window in windows {
            let _ = window.emit("halo-state", payload.clone());
            if let Err(error) = window.hide() {
                log::warn!("Could not hide {}: {error}", window.label());
            }
        }
        let _ = app.emit("halo-state", payload);
        return;
    }

    let payload = serde_json::json!({ "state": state.to_string() });
    for window in windows {
        let _ = window.set_always_on_top(true);
        let _ = window.set_ignore_cursor_events(true);
        let _ = window.emit("halo-state", payload.clone());
        if let Err(error) = window.show() {
            log::warn!("Could not show {}: {error}", window.label());
        }
    }
    let _ = app.emit("halo-state", payload);
}

fn notify(app: &AppHandle, body: &str) {
    if let Err(error) = app
        .notification()
        .builder()
        .title("Codex Halo")
        .body(body)
        .show()
    {
        log::warn!("Could not send system notification: {error}");
    }
}

fn apply_state(
    app: &AppHandle,
    current: &Arc<Mutex<RuntimeState>>,
    timeout_tx: &mpsc::Sender<TimeoutSchedule>,
    state: HaloState,
    remaining: Option<Duration>,
) {
    let (previous, revision) = {
        let mut runtime = current
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        let previous = runtime.state;
        runtime.state = state;
        runtime.revision = runtime.revision.wrapping_add(1);
        (previous, runtime.revision)
    };

    let delay = remaining.or_else(|| state.timeout_ms().map(Duration::from_millis));
    let _ = timeout_tx.send(TimeoutSchedule { revision, delay });
    render_state(app, state);

    if state != previous {
        log::info!("State: {previous} -> {state}");
        match state {
            HaloState::Attention => notify(app, "Codex needs your attention"),
            HaloState::Completed => notify(app, "Codex turn completed"),
            HaloState::Idle | HaloState::Working => {}
        }
    }
}

fn apply_real_event(app: &AppHandle, app_state: &AppState, event: HaloEvent) {
    if app_state.demo_mode.load(Ordering::Acquire) {
        return;
    }
    let enabled = app_state
        .settings
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .enabled;
    if !enabled {
        return;
    }

    let age = unix_time_ms().saturating_sub(event.updated_at);
    let remaining = event
        .state
        .timeout_ms()
        .map(|timeout| Duration::from_millis(timeout.saturating_sub(age)));
    apply_state(
        app,
        &app_state.current,
        &app_state.timeout_tx,
        event.state,
        remaining,
    );
}

pub fn restore_latest_state(app: &AppHandle) {
    let state = app.state::<AppState>();
    let Some(path) = platform::state_file_path() else {
        apply_state(
            app,
            &state.current,
            &state.timeout_tx,
            HaloState::Idle,
            None,
        );
        return;
    };
    match watcher::read_current_state(&path) {
        Ok(event) => apply_real_event(app, &state, event),
        Err(_) => apply_state(
            app,
            &state.current,
            &state.timeout_tx,
            HaloState::Idle,
            None,
        ),
    }
}

fn start_timeout_worker(
    app: AppHandle,
    current: Arc<Mutex<RuntimeState>>,
    receiver: mpsc::Receiver<TimeoutSchedule>,
) {
    std::thread::spawn(move || {
        let mut pending: Option<(u64, Instant)> = None;
        loop {
            let message = match pending {
                Some((_, deadline)) => {
                    let delay = deadline.saturating_duration_since(Instant::now());
                    receiver.recv_timeout(delay)
                }
                None => receiver
                    .recv()
                    .map_err(|_| mpsc::RecvTimeoutError::Disconnected),
            };

            match message {
                Ok(schedule) => {
                    pending = schedule
                        .delay
                        .map(|delay| (schedule.revision, Instant::now() + delay));
                }
                Err(mpsc::RecvTimeoutError::Timeout) => {
                    let Some((expected_revision, _)) = pending.take() else {
                        continue;
                    };
                    let should_hide = {
                        let mut runtime = current
                            .lock()
                            .unwrap_or_else(|poisoned| poisoned.into_inner());
                        if runtime.revision == expected_revision && runtime.state != HaloState::Idle
                        {
                            log::info!("State timeout: {} -> idle", runtime.state);
                            runtime.state = HaloState::Idle;
                            runtime.revision = runtime.revision.wrapping_add(1);
                            true
                        } else {
                            false
                        }
                    };
                    if should_hide {
                        render_state(&app, HaloState::Idle);
                    }
                }
                Err(mpsc::RecvTimeoutError::Disconnected) => break,
            }
        }
    });
}

pub fn run_demo(app: AppHandle) -> Result<(), String> {
    let state = app.state::<AppState>();
    let enabled = state
        .settings
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .enabled;
    if !enabled {
        return Err("Enable Halo before starting Demo Mode".to_owned());
    }
    state
        .demo_mode
        .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
        .map_err(|_| "Demo Mode is already running".to_owned())?;

    let current = state.current.clone();
    let demo_mode = state.demo_mode.clone();
    let timeout_tx = state.timeout_tx.clone();
    std::thread::spawn(move || {
        log::info!("Demo Mode started");
        for (halo_state, duration_ms) in [
            (HaloState::Working, 3_000),
            (HaloState::Attention, 3_000),
            (HaloState::Completed, 2_000),
        ] {
            apply_state(&app, &current, &timeout_tx, halo_state, None);
            std::thread::sleep(Duration::from_millis(duration_ms));
        }
        apply_state(&app, &current, &timeout_tx, HaloState::Idle, None);
        demo_mode.store(false, Ordering::Release);
        log::info!("Demo Mode completed");
        restore_latest_state(&app);
    });
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    if let Err(error) = logging::init() {
        eprintln!("Codex Halo logging could not start: {error}");
    }
    log::info!(
        "Codex Halo v{} starting on {} {}",
        env!("CARGO_PKG_VERSION"),
        std::env::consts::OS,
        std::env::consts::ARCH
    );

    let settings = Arc::new(Mutex::new(AppSettings::load()));
    let current = Arc::new(Mutex::new(RuntimeState {
        state: HaloState::Idle,
        revision: 0,
    }));
    let demo_mode = Arc::new(AtomicBool::new(false));
    let (timeout_tx, timeout_rx) = mpsc::channel();
    let app_state = AppState {
        current: current.clone(),
        settings: settings.clone(),
        demo_mode: demo_mode.clone(),
        timeout_tx: timeout_tx.clone(),
    };

    let app = tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|_, _, _| {
            log::info!("Ignored a second Codex Halo launch");
        }))
        .plugin(tauri_plugin_notification::init())
        .plugin(
            tauri_plugin_autostart::Builder::new()
                .app_name("Codex Halo")
                .build(),
        )
        .manage(app_state)
        .setup(move |app| {
            #[cfg(target_os = "macos")]
            app.handle()
                .set_activation_policy(tauri::ActivationPolicy::Accessory)?;

            let overlays = sync_overlays(app.handle()).map_err(std::io::Error::other)?;
            log::info!("Overlay coverage ready for {} display(s)", overlays.len());
            tray::create_tray(app.handle())?;
            start_timeout_worker(app.handle().clone(), current.clone(), timeout_rx);

            if let Some(state_file) = platform::state_file_path() {
                let handle = app.handle().clone();
                watcher::spawn(state_file, move |event| {
                    let state = handle.state::<AppState>();
                    apply_real_event(&handle, &state, event);
                });
            } else {
                log::error!("State directory is unavailable; file integration is disabled");
            }
            if let Some(sessions_dir) = platform::codex_sessions_dir() {
                let handle = app.handle().clone();
                watcher::spawn_codex_activity(sessions_dir, move |activity| {
                    let app_state = handle.state::<AppState>();
                    if app_state.demo_mode.load(Ordering::Acquire)
                        || !app_state
                            .settings
                            .lock()
                            .unwrap_or_else(|poisoned| poisoned.into_inner())
                            .enabled
                    {
                        return;
                    }
                    apply_state(
                        &handle,
                        &app_state.current,
                        &app_state.timeout_tx,
                        activity.halo_state(),
                        None,
                    );
                });
            } else {
                log::debug!(
                    "Codex session directory is unavailable; hook integration remains active"
                );
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_state,
            get_settings,
            run_demo_command,
            open_logs,
            quit_app
        ])
        .build(tauri::generate_context!())
        .expect("error while building Codex Halo");

    app.run(|app_handle, event| {
        if let tauri::RunEvent::ExitRequested { .. } = event {
            render_state(app_handle, HaloState::Idle);
            log::info!("Codex Halo exited");
        }
    });
}

#[tauri::command]
fn get_state(state: tauri::State<'_, AppState>) -> String {
    state
        .current
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .state
        .to_string()
}

#[tauri::command]
fn get_settings(state: tauri::State<'_, AppState>) -> Result<serde_json::Value, String> {
    let settings = state
        .settings
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    serde_json::to_value(&*settings).map_err(|error| error.to_string())
}

#[tauri::command]
fn run_demo_command(app: AppHandle) -> Result<(), String> {
    run_demo(app)
}

#[tauri::command]
fn open_logs() -> Result<(), String> {
    platform::open_log_dir()
}

#[tauri::command]
fn quit_app(app: AppHandle) {
    render_state(&app, HaloState::Idle);
    app.exit(0);
}
