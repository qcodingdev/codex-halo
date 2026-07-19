# Codex Halo 0.1.4

## Works immediately with Codex Desktop

Codex Halo now observes only the local `task_started` and `task_complete`
lifecycle records that Codex Desktop appends to its session log. It does not
parse, retain, transmit, or log prompt and tool payloads. This makes the
breathing signal work immediately after installation without requiring trust
approval for an executable hook; existing hooks remain a compatibility fallback.
