#!/usr/bin/env python3
"""Read-only routing evidence; remote VS Code metadata is not local-client proof."""
import json
import os
import platform
import shutil
from pathlib import Path


def ancestors():
    pid = os.getppid()
    seen = set()
    result = []
    for _ in range(32):
        if pid <= 1 or pid in seen:
            break
        seen.add(pid)
        proc = Path('/proc') / str(pid)
        try:
            name = (proc / 'comm').read_text().strip()
            result.append(name)
            pid = int((proc / 'stat').read_text().rsplit(') ', 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    return result


def inspect_environment():
    names = ancestors()
    ssh = any(os.environ.get(key) for key in ('SSH_CONNECTION', 'SSH_CLIENT', 'SSH_TTY'))
    program = os.environ.get('TERM_PROGRAM', '')
    vscode = program.lower() == 'vscode' or bool(os.environ.get('VSCODE_IPC_HOOK_CLI'))
    executable = shutil.which('code')
    server_version = None
    server_package = None
    remote_server = False
    if executable:
        resolved = Path(executable).resolve()
        remote_server = any(part.startswith(('.vscode-server', '.vscode-remote')) for part in resolved.parts)
        # Only inspect metadata on the active code executable's path, not all installations.
        if remote_server:
            for parent in resolved.parents:
                candidate = parent / 'package.json'
                try:
                    data = json.loads(candidate.read_text())
                except (OSError, ValueError):
                    continue
                if str(data.get('name', '')).lower() in ('code', 'code-oss', 'code - insiders') and isinstance(data.get('version'), str):
                    server_version = data['version']
                    server_package = str(candidate)
                    break
    cli = any(name == 'codex' or name == 'codex.exe' or name.startswith('codex-') for name in names)
    # Codex itself can be an app server: require an inherited terminal descriptor too.
    terminal = False
    pid = os.getppid()
    for _ in range(32):
        if pid <= 1:
            break
        proc = Path('/proc') / str(pid)
        try:
            name = (proc / 'comm').read_text().strip()
            if name == 'codex' or name.startswith('codex-'):
                for fd in ('0', '1', '2'):
                    try:
                        target = os.readlink(proc / 'fd' / fd)
                        terminal |= target.startswith(('/dev/pts/', '/dev/tty'))
                    except OSError:
                        pass
            pid = int((proc / 'stat').read_text().rsplit(') ', 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    if vscode and cli and terminal:
        route = 'vscode-terminal-native-bell'
    elif vscode or remote_server:
        route = 'confirm-cli-terminal-versus-sidebar'
    elif ssh:
        route = 'ssh-terminal-bell-or-explicit-relay'
    else:
        route = 'inspect-native-desktop'
    return {
        'host_os': platform.system(),
        'ssh_environment_present': ssh,
        'vscode_terminal_evidence': vscode,
        'vscode_remote_server_evidence': remote_server,
        'codex_cli_terminal_evidence': cli and terminal,
        'wsl_environment_present': bool(os.environ.get('WSL_INTEROP') or os.environ.get('WSL_DISTRO_NAME')),
        'recommended_route': route,
        'remote_server_version': server_version,
        'remote_server_version_source': server_package,
        'local_vscode_version': None,
        'local_version_verification': 'Use local Help > About or local code --version before selecting settings.',
    }


if __name__ == '__main__':
    print(json.dumps(inspect_environment(), ensure_ascii=False, indent=2))
