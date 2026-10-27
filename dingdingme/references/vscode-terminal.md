# VS Code terminal completion alerts

Use for Codex CLI in a VS Code integrated terminal, locally or through Remote SSH. The existing editor connection carries the terminal bell through jump hosts. No extra PowerShell window or SSH `RemoteForward` is required.

## 1. Verify versions and execution surface

Run the bundled read-only detector. Confirm an enclosing Codex CLI and VS Code terminal evidence. A sidebar or an app-server process alone is not evidence of an interactive CLI.

Identify the local editor with Help > About or `code --version` in **local** PowerShell/terminal. The `code` command on a remote host may report only the remote server. Record the version and its source. Do not reuse a version from an unrelated installed server. VS Code forks may have different settings; use that editor's settings schema.

For the snippets below, verify the setting exists in that version's Settings UI or Default Settings (JSON). This is especially important at a version transition or when the client and remote server differ.

## 2. Enable Codex's built-in completion bell

Inspect the active Codex home (`CODEX_HOME`, otherwise `~/.codex`), `config.toml`, and relevant project/profile/launch overrides. Back up before editing. Merge the following into the existing `[tui]` table; do not add a duplicate table or rewrite the whole file. Preserve comments and unrelated keys. Preserve a user's existing additional notification events unless they requested completion-only alerts.

```toml
[tui]
notifications = ["agent-turn-complete"]
notification_method = "bel"
notification_condition = "always"
```

`always` makes the alert testable even while the user watches the terminal; `unfocused` can be selected later if preferred. The method is spelled `bel`, not `bell`. Do not change authentication, models, or permissions.

Validate TOML using an available parser (for example Python 3.11+ `tomllib`) and confirm the installed Codex accepts these settings. If this Codex version does not support them, consult its documentation instead of claiming success or installing a new version silently.

When migrating, inspect both JSON and inline TOML hooks. Back up and remove only the old dingdingme notification handler identified by its script path; preserve unrelated Stop hooks, other events, and existing trust records. Do not add a replacement bell hook.

Tell the user to exit the CLI and restart in the **same VS Code terminal**, using `codex resume --last` for the most recent conversation (or `codex resume` to select one). A currently running TUI may not reload these preferences. Do not terminate the user's session yourself. Native TUI settings require no `/hooks` trust step.

## 3. Enable the matching local VS Code settings

Use Ctrl+Shift+P > Preferences: Open User Settings (JSON). Merge entries inside the existing outer object, preserving the user's other settings and valid comma placement. Do not instruct the user to replace the whole file.

### VS Code 1.85.x and 1.86.x (legacy audio cues)

```json
"audioCues.terminalBell": "on",
"terminal.integrated.enableBell": true
```

### VS Code 1.87+ (accessibility signals)

```json
"accessibility.signals.terminalBell": {
    "sound": "on"
}
```

For a visual indicator, add `"terminal.integrated.enableVisualBell": true` only when that setting exists in the installed version. Some intermediate releases use `terminal.integrated.enableBell` for the visual indicator. Confirm the actual schema; do not blindly add deprecated/unknown settings. If the editor flags a setting as unknown, check the local version and defaults before proceeding.

Help: List Signal Sounds (or Help: List Audio Cues in older versions) can preview Terminal Bell. It does not replace enabling the setting. If preview works but an actual bell does not, check the terminal-specific setting and any workspace/remote overrides.

## 4. Test in order

1. The user previews Terminal Bell locally to confirm audio output works.
2. The user opens another VS Code terminal and executes `printf '\a'` in bash. For local PowerShell the equivalent is `[Console]::Write([char]7)`. This tests the editor's actual terminal-bell path, not a captured agent tool pipe.
3. Restart/resume Codex after its TOML change, send a short message, and wait for the reply to end. User confirmation of this step establishes completion alerts work.

If step 2 works and step 3 fails, do not replace the sound or repeat audio settings. Recheck active Codex home, project/profile overrides, `notifications`, `notification_method`, `notification_condition`, restart, and CLI versus sidebar. If legacy hooks remain, distinguish their execution from native TUI notifications using diagnostics rather than manual script success.

## 5. Optional: use the packaged ring.mp3

Offer this only after the default bell works, or when explicitly requested. Keep the default bell if the user does not want to customize it.

VS Code's terminal bell has no supported custom-file picker in these versions. Replacing the installed media file is an **unsupported local customization**: it affects every terminal bell, may cause an installation-integrity warning, and may be overwritten by VS Code updates. Explain this before giving the replacement instructions. If the user prefers to avoid changing application files, keep the built-in sound; do not invent a `soundPath` setting.

For an authorized replacement:

1. Verify the **local** installation directory and version, and locate the existing `terminalBell.mp3`. Do not change the remote `.vscode-server` copy: the local VS Code UI plays the sound. Do not create a guessed target path if no existing file is found.
2. Transfer this package's `assets/sounds/ring.mp3` to the local computer if it is only remote. Use the user's existing SSH alias or actual jump-host route for a one-time `scp -J` transfer. Ask only for missing connection information; never hard-code a previous user's account, addresses, port, or paths. An existing extracted package already contains the ring; reuse it.
3. Verify the source MP3 plays locally. Resolve the actual installation path via the running editor executable or local `code` launcher. The source paths below are examples, not a substitute for checking the installation.
4. Back up the original `terminalBell.mp3` beside it (for example `terminalBell.mp3.dingdingme-original`). Preserve the first original backup on repeated runs. Replace only the existing bell file with the chosen MP3 and keep the filename `terminalBell.mp3`. Record the backup/target paths and optionally compare SHA256 hashes to verify the copy. Do not install codecs or elevate silently if copying fails.
5. Completely exit **all** local VS Code windows, reopen, reconnect, and run `printf '\a'` again. The editor caches audio. Then test one real Codex completion.
6. To undo, restore the original backup to `terminalBell.mp3` and fully restart. After an editor update, verify the new version/path before reapplying; a new installation may need a fresh original backup.

Typical relative media locations beneath the local VS Code installation:

- 1.85.2: `resources/app/out/vs/platform/audioCues/browser/media/terminalBell.mp3`.
- Newer releases may use `resources/app/out/vs/platform/accessibilitySignal/browser/media/terminalBell.mp3`; inspect the installed version rather than assuming this path exists.

On Windows the installation may be under `%LOCALAPPDATA%/Programs/Microsoft VS Code`, `%ProgramFiles%/Microsoft VS Code`, or a user-chosen/portable directory. macOS/Linux layouts differ. Do not provide Windows-only replacement commands without confirming the local OS.

If the custom ring works with `printf '\a'` but no completion sound occurs, the MP3 replacement succeeded: return to step 2's Codex configuration and restart checks.

## Primary sources

- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference): `tui.notifications`, `tui.notification_method`, `tui.notification_condition`.
- [VS Code 1.85.2 audio cues](https://github.com/microsoft/vscode/blob/1.85.2/src/vs/platform/audioCues/browser/audioCueService.ts): legacy setting and packaged MP3 loading.
- [VS Code 1.86 audio cues](https://github.com/microsoft/vscode/blob/1.86.0/src/vs/platform/audioCues/browser/audioCueService.ts).
- [VS Code 1.87 accessibility signals](https://github.com/microsoft/vscode/blob/1.87.0/src/vs/platform/accessibilitySignal/browser/accessibilitySignalService.ts): updated settings and media directory.
- [Current terminal configuration](https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/terminal/common/terminalConfiguration.ts): visual-bell migration. Consult version-tagged source or local defaults for the actual client.
