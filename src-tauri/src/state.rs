use serde::{Deserialize, Serialize};
use std::fmt;

pub const WORKING_TIMEOUT_MS: u64 = 10 * 60 * 1_000;
pub const ATTENTION_TIMEOUT_MS: u64 = 60 * 60 * 1_000;
pub const COMPLETED_DURATION_MS: u64 = 2_000;
pub const MAX_FUTURE_SKEW_MS: u64 = 5 * 60 * 1_000;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HaloState {
    Idle,
    Working,
    Attention,
    Completed,
}

impl fmt::Display for HaloState {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let state = match self {
            Self::Idle => "idle",
            Self::Working => "working",
            Self::Attention => "attention",
            Self::Completed => "completed",
        };
        formatter.write_str(state)
    }
}

impl HaloState {
    pub fn parse(value: &str) -> Option<Self> {
        match value {
            "idle" => Some(Self::Idle),
            "working" => Some(Self::Working),
            "attention" => Some(Self::Attention),
            "completed" => Some(Self::Completed),
            _ => None,
        }
    }

    pub fn timeout_ms(self) -> Option<u64> {
        match self {
            Self::Idle => None,
            Self::Working => Some(WORKING_TIMEOUT_MS),
            Self::Attention => Some(ATTENTION_TIMEOUT_MS),
            Self::Completed => Some(COMPLETED_DURATION_MS),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StateFile {
    pub state: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: u64,
    #[serde(rename = "sessionId", default)]
    pub session_id: Option<String>,
    #[serde(default)]
    pub event: Option<String>,
}

#[derive(Debug, Clone)]
pub struct HaloEvent {
    pub state: HaloState,
    pub updated_at: u64,
}

impl StateFile {
    pub fn validate(self, now_ms: u64) -> Result<HaloEvent, &'static str> {
        let state = HaloState::parse(&self.state).ok_or("unknown state")?;
        if self.updated_at > now_ms.saturating_add(MAX_FUTURE_SKEW_MS) {
            return Err("timestamp is too far in the future");
        }
        if let Some(timeout) = state.timeout_ms() {
            if now_ms.saturating_sub(self.updated_at) >= timeout {
                return Err("state is expired");
            }
        }
        Ok(HaloEvent {
            state,
            updated_at: self.updated_at,
        })
    }
}

pub fn unix_time_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis()
        .try_into()
        .unwrap_or(u64::MAX)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn state_file(state: &str, updated_at: u64) -> StateFile {
        StateFile {
            state: state.to_owned(),
            updated_at,
            session_id: None,
            event: None,
        }
    }

    #[test]
    fn accepts_fresh_state() {
        let event = state_file("working", 9_500)
            .validate(10_000)
            .expect("valid state");
        assert_eq!(event.state, HaloState::Working);
    }

    #[test]
    fn rejects_expired_and_future_states() {
        assert!(state_file("completed", 7_999).validate(10_000).is_err());
        assert!(state_file("working", 10_000 + MAX_FUTURE_SKEW_MS + 1)
            .validate(10_000)
            .is_err());
    }

    #[test]
    fn rejects_unknown_state() {
        assert!(state_file("success", 10_000).validate(10_000).is_err());
    }
}
