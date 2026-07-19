use std::path::PathBuf;

/// Get the state directory where `state.json` is read from.
pub fn state_dir() -> Option<PathBuf> {
    dirs::home_dir().map(|home| home.join(".codex-halo"))
}

/// Get the path to the state file.
pub fn state_file_path() -> Option<PathBuf> {
    state_dir().map(|d| d.join("state.json"))
}

/// Codex Desktop writes append-only session event records here. Halo only
/// observes lifecycle record types and never stores their prompt/tool payloads.
pub fn codex_sessions_dir() -> Option<PathBuf> {
    dirs::home_dir().map(|home| home.join(".codex").join("sessions"))
}

/// Get the platform-native application data directory.
pub fn app_data_dir() -> Option<PathBuf> {
    dirs::data_local_dir().map(|dir| dir.join("Codex Halo"))
}

/// Get the bounded log directory.
pub fn log_dir() -> Option<PathBuf> {
    app_data_dir().map(|dir| dir.join("logs"))
}

/// Open the log directory in the system file explorer.
pub fn open_log_dir() -> Result<(), String> {
    let dir = log_dir().unwrap_or_else(|| PathBuf::from("."));
    std::fs::create_dir_all(&dir).map_err(|error| error.to_string())?;

    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .arg(&dir)
            .spawn()
            .map_err(|error| error.to_string())?;
    }
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("explorer")
            .arg(&dir)
            .spawn()
            .map_err(|error| error.to_string())?;
    }
    Ok(())
}
