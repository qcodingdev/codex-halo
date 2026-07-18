# Release guide

## Gates

- `pnpm check`
- `cargo fmt --manifest-path src-tauri/Cargo.toml --check`
- `cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings`
- `cargo test --manifest-path src-tauri/Cargo.toml`
- isolated Hook install → reinstall → uninstall preservation tests on both OSes
- macOS Intel packaged-app smoke test (overlay, click-through, tray, Demo,
  settings, logs, notification, quit)
- macOS install/verify/uninstall cycle repeated three times
- Universal binary verified with `lipo <binary> -verify_arch x86_64 arm64`
- Windows x64 and macOS target workflows green
- README claims match actual device versus CI evidence

## Build artifacts

```bash
bash scripts/release/package-macos.sh 0.1.2
```

This runs the complete Tauri Universal app bundler, verifies both architectures,
then stages the app, installers, adapter, hook manager, state test, and release
README into `Codex-Halo-macOS-Universal-v0.1.2.zip`. It does not hand-assemble an
incomplete `.app`.

From Windows PowerShell:

```powershell
./scripts/release/package-windows.ps1 0.1.2
```

Output: `Codex-Halo-Windows-x64-v0.1.2.zip`.

## Version and publish

Version values in `package.json`, `src-tauri/Cargo.toml`, and
`src-tauri/tauri.conf.json` must match. Push reviewed `main`, wait for CI, then:

```bash
git tag -a v0.1.2 -m "Codex Halo v0.1.2"
git push origin v0.1.2
```

The tag workflow independently rebuilds both packages and creates the GitHub
Release from `docs/RELEASE_NOTES_v0.1.2.md`.

## Honest validation labels

- **Real-device tested**: exercised on that physical OS/architecture.
- **CI build validated**: compiled/packaged and statically checked in Actions.
- **Universal verified**: the packaged Mach-O contains both architecture slices.

These labels are not interchangeable.

## Known v0.1 boundaries

- unsigned/not notarized;
- primary monitor only;
- ZIP rather than DMG/MSI;
- real-device validation on macOS Intel; Apple Silicon/Windows await community
  or dedicated hardware smoke tests.
