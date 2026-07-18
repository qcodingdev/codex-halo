use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::PathBuf;

const MAX_LOG_BYTES: u64 = 1_048_576;

struct LogWriter {
    file: File,
    mirror_to_stderr: bool,
}

impl Write for LogWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.file.write_all(buffer)?;
        if self.mirror_to_stderr {
            let _ = io::stderr().write_all(buffer);
        }
        Ok(buffer.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        self.file.flush()
    }
}

pub fn init() -> Result<PathBuf, String> {
    let directory = crate::platform::log_dir().ok_or("Log directory is unavailable")?;
    fs::create_dir_all(&directory).map_err(|error| error.to_string())?;

    let path = directory.join("codex-halo.log");
    if path.metadata().map(|metadata| metadata.len()).unwrap_or(0) >= MAX_LOG_BYTES {
        let previous = directory.join("codex-halo.previous.log");
        let _ = fs::remove_file(&previous);
        fs::rename(&path, &previous).map_err(|error| error.to_string())?;
    }

    let file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&path)
        .map_err(|error| error.to_string())?;

    let environment = env_logger::Env::new()
        .filter_or("CODEX_HALO_LOG", "info")
        .write_style_or("CODEX_HALO_LOG_STYLE", "never");
    env_logger::Builder::from_env(environment)
        .format_timestamp_millis()
        .format_target(false)
        .target(env_logger::Target::Pipe(Box::new(LogWriter {
            file,
            mirror_to_stderr: cfg!(debug_assertions),
        })))
        .try_init()
        .map_err(|error| error.to_string())?;
    Ok(path)
}
