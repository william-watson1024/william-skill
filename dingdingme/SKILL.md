---
name: dingdingme
description: Create, install, or troubleshoot a Codex Stop hook that plays a sound and sends a native Windows or Linux notification, including WSL and SSH forwarding.
---

# Ding Ding Me

Use this skill when the user asks for a completion sound or desktop notification from Codex.

## Set up or change a hook

1. Identify where Codex is running. Detect SSH first, then WSL, then native Windows or Linux. The hook runs on the Codex host, which may differ from the visible editor or SSH client.
2. Check which notification and audio tools are available. Use the matching scripts in `scripts/`; read [platform-support.md](references/platform-support.md) for WSL and SSH details.
3. Keep the user's chosen sound. If the package's `assets/sounds/ring.mp3` is unsuitable or unavailable in the target environment, ask before replacing it or installing codecs.
4. When registering or changing a hook, inspect the active `hooks.json`, preserve unrelated entries, avoid duplicates, and write UTF-8 without a BOM. Use an asynchronous command hook for sound playback.
5. Never bypass Codex hook trust review. Tell the user to review and trust the changed hook in Codex CLI `/hooks` before relying on it.
6. Verify configuration syntax and script availability. Ensure successful `Stop` handlers write valid JSON (`{}`) to stdout; keep diagnostics on stderr.

Use the absolute package path in the hook command. On Windows, invoke `scripts/windows-notify.ps1` with `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File`. On WSL, Linux, and remote SSH sessions, invoke `bash scripts/notify.sh`; it selects the platform route at runtime. Keep the hook asynchronous and use the Codex `Stop` event.

## Platform routing

- **Windows:** use `scripts/windows-notify.ps1` for a Windows Toast with high priority and MP3 playback.
- **WSL:** if Windows interop and `wslpath` work, `scripts/notify.sh` invokes the host PowerShell script. Otherwise use the Linux desktop route.
- **Linux desktop:** use `notify-send` with critical urgency and an installed MP3 player. Do not install tools without the user's approval.
- **SSH:** send the fixed completion event through `scripts/ssh-relay-client.sh`. For a Windows client, a loopback-only listener and an SSH `RemoteForward` are required. Use a random token, keep the remote port bound to `127.0.0.1`, and fall back to a terminal bell if the relay is unavailable. Do not expose a listener on a public interface.

The user may keep the package in a temporary folder. Do not install it under the global skills directory unless asked.
