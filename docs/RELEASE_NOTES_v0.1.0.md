# Codex Halo 0.1.0

Your screen now knows when Codex is working, waiting, or done.

## Highlights

- Blue working flow, yellow attention pulse, and green completion sweep
- Cyber Blue, Sakura, and Minimal themes
- Native click-through, focus-free Tauri overlay
- Synchronized edge coverage across every connected display
- Local-only event-driven state bridge with no server or telemetry
- Safe, idempotent Codex lifecycle-hook installation and precise uninstall
- Single-instance menu-bar/system-tray controls with a native Halo icon
- Demo Mode, notifications, and Start at Login
- One Universal macOS package for Intel and Apple Silicon
- Portable Windows 10/11 x64 package

## Install

Download the ZIP for your platform, extract all files, then run the included
installer. macOS builds are currently unsigned, so first launch requires
right-clicking `Codex Halo.app` and choosing **Open**.

Review and trust the installed Halo command hooks from Codex `/hooks`.

## Integrity

Both packages are built from this tag by GitHub Actions. Codex Halo is an
independent community project and is not affiliated with or endorsed by OpenAI.

## Performance

Measured on a 2018 Intel Core i9-8950HK MacBook Pro with 32 GB RAM and
macOS 15.7.7, using the packaged release app:

| State | Main-process CPU | Main-process RSS |
|---|---:|---:|
| Idle | 0.0% in 10/10 samples | 50–51 MiB |
| Working, two displays | 3.1–3.5% after warm-up | 50–51 MiB |

Samples were collected at two-second intervals with macOS `top`; RSS was
cross-checked with `ps`. The active measurement drove a 3360×2100 Retina
display and a 2560×1440 external display simultaneously. The Intel application
bundle is 13 MiB before ZIP packaging, and the self-contained Universal release
ZIP is 7.49 MiB. The production web payload is 197.61 KB JavaScript (62.21 KB
gzip) and 5.53 KB CSS (1.31 KB gzip).

## Validation

- Frontend lint, TypeScript, and production build passed.
- Rust format, warning-free Clippy, and all 6 unit tests passed.
- The CI-built Universal package completed three install/verify cycles on Intel
  hardware, including repeat-install idempotency, five lifecycle-event probes,
  privacy checks, two clean uninstalls, and a final retained installation.
- The packaged app completed idle, working, attention, completed, timeout,
  relaunch, log, and clean-exit smoke tests on real hardware.
- Two-display working/attention screenshots, one-status-icon inspection, and a
  forced second-launch rejection passed on real hardware.
- Safe Hook install, repeat-install, verification, unrelated-Hook preservation,
  privacy, and uninstall tests passed in isolated macOS fixtures.
- Apple Silicon and Windows are built and tested by CI; they are not claimed as
  real-hardware validation for this release.
