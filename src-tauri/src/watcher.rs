use crate::state::{unix_time_ms, HaloEvent, HaloState, StateFile};
use notify::{Config, RecommendedWatcher, RecursiveMode, Watcher};
use std::sync::mpsc;
use std::time::Duration;
use std::{
    collections::HashMap,
    fs::{self, File},
    io::{BufRead, BufReader, Seek, SeekFrom},
    path::{Path, PathBuf},
};

const READ_RETRIES: usize = 3;
const RETRY_DELAY: Duration = Duration::from_millis(25);
const WATCHER_RESTART_DELAY: Duration = Duration::from_secs(5);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CodexActivity {
    Started,
    Completed,
}

impl CodexActivity {
    pub fn halo_state(self) -> HaloState {
        match self {
            Self::Started => HaloState::Working,
            Self::Completed => HaloState::Completed,
        }
    }
}

fn activity_from_line(line: &str) -> Option<CodexActivity> {
    // Match only the top-level event record shape. User text is JSON-escaped in
    // session records, so this avoids parsing, retaining, or logging payloads.
    if line.contains(r#""type":"event_msg","payload":{"type":"task_started"#) {
        Some(CodexActivity::Started)
    } else if line.contains(r#""type":"event_msg","payload":{"type":"task_complete"#) {
        Some(CodexActivity::Completed)
    } else {
        None
    }
}

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

fn is_session_file(path: &Path) -> bool {
    path.extension().and_then(|extension| extension.to_str()) == Some("jsonl")
}

fn seed_session_offsets(
    directory: &Path,
    offsets: &mut HashMap<PathBuf, u64>,
) -> Result<(), String> {
    for entry in fs::read_dir(directory).map_err(|error| error.to_string())? {
        let entry = entry.map_err(|error| error.to_string())?;
        let path = entry.path();
        if path.is_dir() {
            seed_session_offsets(&path, offsets)?;
        } else if is_session_file(&path) {
            let length = entry.metadata().map_err(|error| error.to_string())?.len();
            offsets.insert(path, length);
        }
    }
    Ok(())
}

fn read_new_activities(
    path: &Path,
    offsets: &mut HashMap<PathBuf, u64>,
) -> Result<Vec<CodexActivity>, String> {
    let length = fs::metadata(path).map_err(|error| error.to_string())?.len();
    let previous = offsets.get(path).copied().unwrap_or(0);
    // Codex may replace a JSONL file atomically. A shorter file means the
    // previous byte offset is no longer valid, so rescan the replacement.
    let start = if length < previous { 0 } else { previous };
    if start == length {
        return Ok(Vec::new());
    }

    let mut file = File::open(path).map_err(|error| error.to_string())?;
    file.seek(SeekFrom::Start(start))
        .map_err(|error| error.to_string())?;
    let mut reader = BufReader::new(file);
    let mut activities = Vec::new();
    let mut consumed = 0_u64;
    loop {
        let mut bytes = Vec::new();
        let read = reader
            .read_until(b'\n', &mut bytes)
            .map_err(|error| error.to_string())?;
        if read == 0 {
            break;
        }
        if bytes.last() != Some(&b'\n') {
            break;
        }
        consumed += read as u64;
        if let Ok(line) = std::str::from_utf8(&bytes) {
            if let Some(activity) = activity_from_line(line) {
                activities.push(activity);
            }
        }
    }
    offsets.insert(path.to_path_buf(), start + consumed);
    Ok(activities)
}

fn event_may_touch_session(event: &notify::Event, sessions_dir: &Path) -> bool {
    event
        .paths
        .iter()
        .any(|path| path.starts_with(sessions_dir))
}

fn collect_session_files(directory: &Path, files: &mut Vec<PathBuf>) -> Result<(), String> {
    for entry in fs::read_dir(directory).map_err(|error| error.to_string())? {
        let path = entry.map_err(|error| error.to_string())?.path();
        if path.is_dir() {
            collect_session_files(&path, files)?;
        } else if is_session_file(&path) {
            files.push(path);
        }
    }
    Ok(())
}

fn watch_activity_once<F>(sessions_dir: &Path, mut on_activity: F) -> Result<(), String>
where
    F: FnMut(CodexActivity),
{
    if !sessions_dir.is_dir() {
        return Err("Codex sessions directory is unavailable".to_owned());
    }

    let (event_tx, event_rx) = mpsc::channel();
    let mut watcher = RecommendedWatcher::new(
        move |event| {
            let _ = event_tx.send(event);
        },
        Config::default(),
    )
    .map_err(|error| error.to_string())?;
    watcher
        .watch(sessions_dir, RecursiveMode::Recursive)
        .map_err(|error| error.to_string())?;

    let mut offsets = HashMap::new();
    seed_session_offsets(sessions_dir, &mut offsets)?;
    log::info!("Watching Codex session lifecycle events");

    loop {
        match event_rx.recv() {
            Ok(Ok(event)) if event_may_touch_session(&event, sessions_dir) => {
                let mut files = Vec::new();
                if let Err(error) = collect_session_files(sessions_dir, &mut files) {
                    log::debug!("Could not enumerate Codex session files: {error}");
                    continue;
                }
                for path in files {
                    match read_new_activities(&path, &mut offsets) {
                        Ok(activities) => activities.into_iter().for_each(&mut on_activity),
                        Err(error) => log::debug!("Ignoring Codex session update: {error}"),
                    }
                }
            }
            Ok(Ok(_)) => {}
            Ok(Err(error)) => log::warn!("Codex activity watcher reported an error: {error}"),
            Err(error) => return Err(format!("Codex activity watcher disconnected: {error}")),
        }
    }
}

pub fn spawn_codex_activity<F>(sessions_dir: PathBuf, on_activity: F)
where
    F: Fn(CodexActivity) + Send + Sync + 'static,
{
    std::thread::spawn(move || loop {
        let callback = &on_activity;
        if let Err(error) = watch_activity_once(&sessions_dir, callback) {
            log::debug!("Codex activity watcher stopped: {error}; retrying");
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

    #[test]
    fn recognizes_lifecycle_records_without_parsing_payloads() {
        assert_eq!(
            activity_from_line(r#"{"type":"event_msg","payload":{"type":"task_started"}}"#),
            Some(CodexActivity::Started)
        );
        assert_eq!(
            activity_from_line(r#"{"type":"event_msg","payload":{"type":"task_complete"}}"#),
            Some(CodexActivity::Completed)
        );
        assert_eq!(activity_from_line(r#"{"type":"response_item"}"#), None);
    }
}
