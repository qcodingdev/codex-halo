# Contributing

Thanks for helping make Codex state visible without making the desktop noisy.

1. Open an issue for behavioral or visual changes before a large implementation.
2. Keep the local-only boundary: no servers, telemetry, prompt capture, or code access.
3. Run `pnpm check`, `cargo fmt --check`, `cargo clippy -- -D warnings`, and
   `cargo test` before opening a pull request.
4. Include a short screen recording for visual changes and tests for state,
   timeout, hook, or installer changes.
5. State which platforms were tested on real hardware; do not label a CI build
   as a real-device smoke test.
