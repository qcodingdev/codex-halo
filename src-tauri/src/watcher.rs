use crate::state::{unix_time_ms, HaloEvent, StateFile};
use notify::{Config, RecommendedWatcher, RecursiveMode, Watcher};
use std::path::{Path, PathBuf};
use std::sync::mpsc;
use std::time::Duration;

const READ_RETRIES: usize = 3;
const RETRY_DELAY: Duration = Duration::from_millis(25);
const WATCHER_RESTART_DELAY: Duration = Duration::from_secs(5);

pub fn read_current_state(path: &Path) -> Result<HaloEvent, String> {
    let contents = std::fs::read_to_string(path).map_err(|error| error.to_string())?;
    let state_file: StateFile =
        serde_json::from_str(&contents).map_err(|error| error.to_string())?;
    state_file.validate(unix_time_ms()).map_err(str::to_owned)
}

fn read_with_retry(path: &Path) -> Result<HaloEvent, String> {
    let mut last_error = String::new();
    for attempt in 0..READ_RETRIES {
        match read_current_state(path) {
            Ok(event) => return Ok(event),
            Err(error) => last_error = error,
        }
        if attempt + 1 < READ_RETRIES {
            std::thread::sleep(RETRY_DELAY);
        }
    }
    Err(last_error)
}

fn event_may_touch_state(event: &notify::Event, state_file: &Path) -> bool {
    event.paths.iter().any(|path| {
        path == state_file
            || path
                .file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name == "state.json" || name.starts_with("state.json."))
    })
}

fn watch_once<F>(state_file: &Path, mut on_state: F) -> Result<(), String>
where
    F: FnMut(HaloEvent),
{
    let parent = state_file
        .parent()
        .ok_or("State file path has no parent directory")?;
    std::fs::create_dir_all(parent).map_err(|error| error.to_string())?;

    let (event_tx, event_rx) = mpsc::channel();
    let mut watcher = RecommendedWatcher::new(
        move |event| {
            let _ = event_tx.send(event);
        },
        Config::default(),
    )
    .map_err(|error| error.to_string())?;
    watcher
        .watch(parent, RecursiveMode::NonRecursive)
        .map_err(|error| error.to_string())?;

    log::info!("Watching local state directory");
    let mut last_timestamp = 0;
    if let Ok(event) = read_current_state(state_file) {
        last_timestamp = event.updated_at;
        on_state(event);
    }

    loop {
        match event_rx.recv() {
            Ok(Ok(event)) if event_may_touch_state(&event, state_file) => {
                match read_with_retry(state_file) {
                    Ok(event) if event.updated_at > last_timestamp => {
                        last_timestamp = event.updated_at;
                        on_state(event);
                    }
                    Ok(_) => log::debug!("Ignoring duplicate or older state event"),
                    Err(error) => log::warn!("Ignoring invalid state file update: {error}"),
                }
            }
            Ok(Ok(_)) => {}
            Ok(Err(error)) => log::warn!("File watcher reported an error: {error}"),
            Err(error) => return Err(format!("File watcher channel disconnected: {error}")),
        }
    }
}

pub fn spawn<F>(state_file: PathBuf, on_state: F)
where
    F: Fn(HaloEvent) + Send + Sync + 'static,
{
    std::thread::spawn(move || loop {
        let callback = &on_state;
        if let Err(error) = watch_once(&state_file, callback) {
            log::error!("State watcher stopped: {error}; retrying");
            std::thread::sleep(WATCHER_RESTART_DELAY);
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_valid_state_file() {
        let path =
            std::env::temp_dir().join(format!("codex-halo-state-{}.json", std::process::id()));
        let now = crate::state::unix_time_ms();
        std::fs::write(&path, format!(r#"{{"state":"working","updatedAt":{now}}}"#))
            .expect("write state fixture");
        let event = read_current_state(&path).expect("valid state");
        assert_eq!(event.state, crate::state::HaloState::Working);
        let _ = std::fs::remove_file(path);
    }
}
