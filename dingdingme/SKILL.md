---
name: dingdingme
description: Configure or troubleshoot Codex completion sounds and alerts, preferring VS Code terminal bells for Remote SSH and supporting optional custom sounds and native desktop hooks.
---

# Ding Ding Me

Set up completion alerts where the user can actually hear them. For Codex CLI inside VS Code, including Remote SSH through jump hosts, prefer Codex's built-in terminal bell. No extra extension, listener, or SSH forward is needed for that route.

## Detect before configuring

Run `python3 scripts/detect-environment.py` using this package's absolute path, or inspect equivalent evidence if Python is unavailable. Report the host environment separately from the user's local editor. Check VS Code evidence even when SSH variables are present; SSH variables can also be absent inside Remote SSH.

- **VS Code + Codex CLI terminal:** follow [vscode-terminal.md](references/vscode-terminal.md), including version verification, settings, restart, and end-to-end testing. This is the default for VS Code Remote SSH, even with a jump host.
- **SSH but editor unknown:** first check `TERM_PROGRAM`, `VSCODE_IPC_HOOK_CLI`, the enclosing processes, and the active `code` executable. If still unclear, ask whether the user runs CLI in VS Code's terminal or uses its Codex sidebar. Do not silently treat all SSH clients as VS Code.
- **VS Code Codex sidebar:** the CLI `[tui]` settings do not configure sidebar completion alerts. Check the installed extension's supported settings. Do not promise the terminal route will notify for sidebar turns. Respect a preference against installing extensions; explain the limitation and offer the integrated-terminal CLI route.
- **SSH outside VS Code:** offer the existing terminal's bell first. Use the relay in [platform-support.md](references/platform-support.md) only when desktop popups or custom local playback are wanted and the user accepts a local listener and forwarding.
- **Native Windows, WSL, or Linux desktop:** use the native notification route in [platform-support.md](references/platform-support.md).

Do not install a VS Code extension, Python, codecs, or system packages without user authorization. Keep the package in its current location unless installation is requested.

## VS Code defaults

Use Codex's native `tui.notifications`, `tui.notification_method = "bel"`, and `tui.notification_condition = "always"` for terminal completion alerts. Preserve existing configuration and unrelated notifications. Do not add a Stop hook for the same event. If migrating from this skill's older hook, back up and remove only the positively identified old handler; preserve unrelated handlers and trust state.

Verify the **local VS Code version** before giving version-specific settings. Remote Server package metadata is useful evidence, but can be stale or differ from the active local client. Ask for Help > About or local `code --version` when needed. Never guess the client's version from an arbitrary installed server directory.

Guide the user to VS Code **User Settings (JSON)** on their local computer, not the repository, remote server, or Codex TOML. Supply only the applicable setting names; see the reference for old/new schemas. A sound-preview command is a test, not the place to enable a sound.

Explain that this route supplies a sound and optional terminal bell indicator, not a Windows notification-center popup. The optional ring replacement is a separate local step; follow the backup, version, restart, and restore guidance in the reference. Never claim custom sound selection is a supported VS Code setting.

## Native hooks only

Inspect active `hooks.json` and inline hooks before editing. Preserve unrelated entries, avoid duplicates, use absolute script paths, write UTF-8 without BOM, and run sound playback as an asynchronous `Stop` command hook. Successful Stop scripts must return `{}` on stdout and put diagnostics on stderr.

Never change hook trust hashes or bypass review. Tell the user to review and trust any changed hook definition in Codex CLI `/hooks`. This requirement applies to hook changes, not the built-in TUI bell configuration.

## Verify the outcome

Separate these checks: local sound preview, `printf '\a'` in the actual VS Code terminal, then a real Codex turn after restart. Tool stdout is captured and may not reach the user's terminal: do not treat `printf` inside an agent tool as an audible test. A successful manual script run does not prove that a lifecycle hook executed.

If `printf '\a'` plays the desired sound but Codex completion does not, leave the sound file and VS Code settings alone. Check active Codex configuration, restart, event selection, focus policy, configuration overrides, and whether the user is using CLI or sidebar. Report configuration validation separately from user-confirmed audible success.
