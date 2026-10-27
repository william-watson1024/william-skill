# Platform support

## Windows

`scripts/windows-notify.ps1` sends a Windows Toast with `Priority=High` and plays `assets/sounds/ring.mp3` through Windows MCI. It prefers the installed ChatGPT app identity and falls back to the registered Windows PowerShell identity. Toast priority is a Windows hint; notification settings, Do Not Disturb, and device state can still affect banners.

The notification sender appears as ChatGPT when that app identity is available. Windows' per-app notification settings control its priority and whether it is allowed during Do Not Disturb.

## WSL

`scripts/notify.sh` uses Windows interop only when `WSL_INTEROP`, `powershell.exe`, and `wslpath` are available. It converts the script path with `wslpath -w`; if that path cannot be used or PowerShell fails, it falls back to Linux notification/audio tools. When a WSL process is itself running over SSH, the SSH relay route takes precedence.

Do not assume Linux desktop notification services are available in WSL. Check `notify-send` and the desktop bus before relying on the Linux route.

## Linux desktop

The local route uses `notify-send --urgency=critical` and the first available player among `mpv`, `ffplay`, and `mpg123`. The hook does not install packages. A desktop notification service and audio session must be available to the user running Codex.

## SSH relay to Windows

The hook process runs on the remote host, so copy the package scripts to a path available on that host and register the remote hook there. The Windows package folder is not automatically visible to the remote machine. Keep a local relay listener running on the Windows client and create a reverse SSH forward that is bound only to the remote loopback interface:

```sshconfig
Host your-host-alias
    RemoteForward 127.0.0.1:PORT 127.0.0.1:PORT
    ExitOnForwardFailure yes
```

Replace `PORT` with the chosen high, unused port. Start `scripts/ssh-relay-listener.py` on the SSH client with that port and a token file. For example, on Windows:

```powershell
py -3 .\scripts\ssh-relay-listener.py --port 38473 --token-file "$env:LOCALAPPDATA\Codex\dingdingme\relay.token"
```

On Linux or WSL:

```sh
python3 scripts/ssh-relay-listener.py --port 38473 --token-file "$HOME/.config/dingdingme/relay.token"
```

Store the same 64-character random hex token in the remote user's `~/.config/dingdingme/relay.conf`:

```text
PORT=38473
TOKEN=<64-hex-character-token>
```

Set the remote config file permissions to `600`. Keep the Windows token file under the user's profile with user-only read access. The listener binds only to `127.0.0.1`; the remote forward also binds only to remote loopback. The client must reconnect after adding `RemoteForward`; the current SSH session does not gain a new forward automatically.

If the SSH server disallows TCP forwarding, do not widen the listener to a public interface. Keep the terminal-bell fallback or ask the server administrator to enable an appropriate remote forward.

When the SSH client itself runs in WSL, run the Python listener in that WSL environment so the reverse forward targets WSL loopback; its notification dispatcher can then call the Windows host through WSL interop. When the SSH client runs on native Windows, run the listener with Windows Python.
