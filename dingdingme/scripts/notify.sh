#!/usr/bin/env bash
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
sound_path="$script_dir/../assets/sounds/ring.mp3"

bell() {
  if [ -w /dev/tty ]; then
    printf '\a' > /dev/tty 2>/dev/null || true
  else
    printf '\a' >&2
  fi
}

# The hook executes remotely under SSH; route before considering local WSL interop.
if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
  exec bash "$script_dir/ssh-relay-client.sh"
fi

if [ -n "${WSL_INTEROP:-}" ] && command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
  if win_script=$(wslpath -w "$script_dir/windows-notify.ps1" 2>/dev/null); then
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "$win_script"
    status=$?
    if [ "$status" -eq 0 ]; then
      exit 0
    fi
    printf 'Ding Ding Me: Windows interop failed; trying the Linux desktop path.\n' >&2
  fi
fi

success=0
if command -v notify-send >/dev/null 2>&1; then
  if notify-send --urgency=critical --app-name=Codex 'Codex' 'This Codex turn is complete.'; then
    success=1
  else
    printf 'Ding Ding Me: notify-send could not reach the desktop notification service.\n' >&2
  fi
else
  printf 'Ding Ding Me: notify-send is not installed.\n' >&2
fi

if [ -f "$sound_path" ]; then
  if command -v mpv >/dev/null 2>&1; then
    nohup mpv --no-video --really-quiet "$sound_path" >/dev/null 2>&1 </dev/null &
    success=1
  elif command -v ffplay >/dev/null 2>&1; then
    nohup ffplay -nodisp -autoexit -loglevel error "$sound_path" >/dev/null 2>&1 </dev/null &
    success=1
  elif command -v mpg123 >/dev/null 2>&1; then
    nohup mpg123 -q "$sound_path" >/dev/null 2>&1 </dev/null &
    success=1
  else
    printf 'Ding Ding Me: install mpv, ffplay, or mpg123 to play MP3 audio.\n' >&2
  fi
else
  printf 'Ding Ding Me: sound file is missing: %s\n' "$sound_path" >&2
fi

if [ "$success" -eq 0 ]; then
  bell
  exit 1
fi

# A successful Stop hook must return valid JSON on stdout.
printf '{}\n'
