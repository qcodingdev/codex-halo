use serde::{Deserialize, Serialize};
use std::fmt;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

use crate::platform;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(default, deny_unknown_fields)]
pub struct AppSettings {
    pub enabled: bool,
    pub theme: ThemeId,
    #[serde(rename = "startAtLogin")]
    pub start_at_login: bool,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            enabled: true,
            theme: ThemeId::CyberBlue,
            start_at_login: false,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ThemeId {
    CyberBlue,
    Sakura,
    Minimal,
}

impl fmt::Display for ThemeId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let id = match self {
            Self::CyberBlue => "cyber-blue",
            Self::Sakura => "sakura",
            Self::Minimal => "minimal",
        };
        formatter.write_str(id)
    }
}

impl ThemeId {
    pub fn parse(value: &str) -> Option<Self> {
        match value {
            "cyber-blue" => Some(Self::CyberBlue),
            "sakura" => Some(Self::Sakura),
            "minimal" => Some(Self::Minimal),
            _ => None,
        }
    }
}

impl AppSettings {
    pub fn config_path() -> Option<PathBuf> {
        platform::app_data_dir().map(|dir| dir.join("settings.json"))
    }

    pub fn load() -> Self {
        let Some(path) = Self::config_path() else {
            log::warn!("Application data directory is unavailable; using default settings");
            return Self::default();
        };
        Self::load_from(&path)
    }

    fn load_from(path: &Path) -> Self {
        match fs::read_to_string(path) {
            Ok(contents) => match serde_json::from_str::<Self>(&contents) {
                Ok(settings) => settings,
                Err(error) => {
                    log::warn!("Settings are invalid; restoring defaults: {error}");
                    let defaults = Self::default();
                    if let Err(save_error) = defaults.save_to(path) {
                        log::warn!("Could not replace invalid settings: {save_error}");
                    }
                    defaults
                }
            },
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
                let defaults = Self::default();
                if let Err(save_error) = defaults.save_to(path) {
                    log::warn!("Could not create default settings: {save_error}");
                }
                defaults
            }
            Err(error) => {
                log::warn!("Could not read settings; using defaults: {error}");
                Self::default()
            }
        }
    }

    pub fn save(&self) -> Result<(), String> {
        let path = Self::config_path().ok_or("Application data directory is unavailable")?;
        self.save_to(&path)
    }

    fn save_to(&self, path: &Path) -> Result<(), String> {
        let parent = path
            .parent()
            .ok_or("Settings path has no parent directory")?;
        fs::create_dir_all(parent).map_err(|error| error.to_string())?;

        let temporary = path.with_extension("json.tmp");
        let contents = serde_json::to_vec_pretty(self).map_err(|error| error.to_string())?;
        let mut file = OpenOptions::new()
            .create(true)
            .truncate(true)
            .write(true)
            .open(&temporary)
            .map_err(|error| error.to_string())?;
        file.write_all(&contents)
            .map_err(|error| error.to_string())?;
        file.sync_all().map_err(|error| error.to_string())?;

        if let Err(error) = fs::rename(&temporary, path) {
            // Windows does not replace an existing destination with rename.
            if path.exists() {
                fs::remove_file(path).map_err(|remove_error| {
                    format!("Could not replace settings ({error}); remove failed: {remove_error}")
                })?;
                fs::rename(&temporary, path).map_err(|rename_error| rename_error.to_string())?;
            } else {
                return Err(error.to_string());
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_path(name: &str) -> PathBuf {
        std::env::temp_dir().join(format!(
            "codex-halo-settings-{}-{name}.json",
            std::process::id()
        ))
    }

    #[test]
    fn round_trips_settings() {
        let path = test_path("round-trip");
        let expected = AppSettings {
            enabled: false,
            theme: ThemeId::Sakura,
            start_at_login: true,
        };
        expected.save_to(&path).expect("save settings");
        assert_eq!(AppSettings::load_from(&path), expected);
        let _ = fs::remove_file(path);
    }

    #[test]
    fn invalid_settings_restore_defaults() {
        let path = test_path("invalid");
        fs::write(&path, b"{ definitely not json").expect("write fixture");
        assert_eq!(AppSettings::load_from(&path), AppSettings::default());
        assert_eq!(AppSettings::load_from(&path), AppSettings::default());
        let _ = fs::remove_file(path);
    }
}
