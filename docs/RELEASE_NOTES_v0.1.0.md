# Codex Halo 0.1.0

Your screen now knows when Codex is working, waiting, or done.

## Highlights

- Blue working flow, yellow attention pulse, and green completion sweep
- Cyber Blue, Sakura, and Minimal themes
- Native click-through, focus-free Tauri overlay
- Local-only event-driven state bridge with no server or telemetry
- Safe, idempotent Codex lifecycle-hook installation and precise uninstall
- Menu-bar/system-tray controls, Demo Mode, notifications, and Start at Login
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
| Idle | 0.0% in 6/6 samples | 48–51 MiB |
| Working animation | 1.6–1.7% after warm-up | 50–51 MiB |

Samples were collected at two-second intervals with macOS `top`; RSS was
cross-checked with `ps`. The Intel application bundle is 13 MiB before ZIP
packaging. The production web payload is 197.61 KB JavaScript (62.22 KB gzip)
and 5.27 KB CSS (1.26 KB gzip).

## Validation

- Frontend lint, TypeScript, and production build passed.
- Rust format, warning-free Clippy, and all 6 unit tests passed.
- A packaged Intel app completed idle, working, attention, completed, timeout,
  relaunch, log, and clean-exit smoke tests on real hardware.
- Safe Hook install, repeat-install, verification, unrelated-Hook preservation,
  privacy, and uninstall tests passed in isolated macOS fixtures.
- Apple Silicon and Windows are built and tested by CI; they are not claimed as
  real-hardware validation for this release.
