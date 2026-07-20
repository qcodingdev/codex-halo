# Troubleshooting

## Demo Mode does not show a halo

1. Confirm **Enable Halo** is checked in the tray menu.
2. Quit and reopen Codex Halo.
3. Open **Logs** from the tray and inspect the newest error.
4. Run the included Verify script.

Demo Mode does not require Codex. If it fails, the problem is the app/overlay,
not Codex lifecycle detection.

## Demo Mode works, Codex events do not

1. Confirm **Enable Halo** is checked in the tray menu.
2. Quit and reopen Halo after updating to the latest release.
3. Start a new Codex task, then inspect the Halo log for `Watching Codex session
   lifecycle events` and `idle -> working`.
4. Use the included Test State script with `working` to distinguish a display
   issue from lifecycle detection.

## macOS says the developer cannot be verified

The first release is unsigned. Right-click `Codex Halo.app`, choose **Open**,
then choose **Open** again. Do not disable Gatekeeper globally.

## macOS says the app is damaged

Download the release ZIP again and extract all files together. Do not move just
the installer away from its `hooks` and `support` folders. If macOS still blocks
the app, open an issue with the exact message; do not run commands that disable
system security.

## The tray icon is missing

- macOS: check Control Center/menu-bar item visibility and
  `pgrep -x codex-halo-lite`.
- Windows: check the hidden-icons area and Task Manager for `CodexHalo.exe`.

Use the app's Quit item before relaunching.

## A connected display has no halo

1. Confirm the display is online and mirroring is disabled.
2. Quit and reopen Halo after changing the display arrangement.
3. Open the log and look for `Overlay coverage ready for N display(s)`.
4. Run Demo Mode and attach the display arrangement plus log to an issue.

## A state remains visible

Working times out after 30 minutes, attention after 60 minutes, and completed
after 2 seconds. Updates with old timestamps are ignored. Run Test State with
`idle`, then inspect the log for an invalid/stale-state message.

## CPU remains active while idle

Confirm the state is idle and the overlay is hidden. A correctly installed v0.1
uses filesystem events plus a 500 ms metadata check limited to eight recent
session files; it does not rescan session history. If activity persists, capture
several Activity Monitor/Task Manager samples plus the log and open an issue.

## Safe recovery

1. Quit Halo.
2. Move the platform `settings.json` aside to restore defaults.
3. Re-run the installer; it does not add hooks or require a Codex confirmation.
4. Re-run Verify.

Never restore an old configuration backup wholesale: that could overwrite hooks
added since the backup. The bundled installer removes only obsolete marked Halo
entries from older releases.
