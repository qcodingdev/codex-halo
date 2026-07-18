# Security Policy

## Supported versions

Security fixes are provided for the latest release.

## Report a vulnerability

Please use GitHub's private security advisory form instead of opening a public
issue. Include the affected version, platform, reproduction steps, and impact.
Do not include prompts, source code, tokens, or other sensitive user data.

## Trust boundary

Codex Halo has no HTTP server, cloud service, update downloader, account, or
telemetry. Its hook adapter writes only lifecycle state metadata to
`~/.codex-halo/state.json`. Installation changes only Halo's entries in
`~/.codex/hooks.json` after creating a timestamped backup.
