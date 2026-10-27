#!/usr/bin/env python3
"""Loopback-only authenticated notification relay for SSH RemoteForward."""

from __future__ import annotations

import argparse
import hmac
import os
import re
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


HERE = Path(__file__).resolve().parent


def launch_notification() -> None:
    if os.name == "nt":
        command = [
            "powershell.exe",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-WindowStyle",
            "Hidden",
            "-File",
            str(HERE / "windows-notify.ps1"),
        ]
        options = {"creationflags": getattr(subprocess, "CREATE_NO_WINDOW", 0)}
    else:
        command = ["bash", str(HERE / "notify.sh")]
        options = {"start_new_session": True}

    subprocess.Popen(
        command,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        cwd=str(HERE),
        **options,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--token-file", type=Path, required=True)
    args = parser.parse_args()

    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    if not args.token_file.is_file():
        parser.error("--token-file must name an existing file")

    token = args.token_file.read_text(encoding="ascii").strip()
    if not re.fullmatch(r"[0-9a-fA-F]{64}", token):
        parser.error("token file must contain exactly 64 hexadecimal characters")

    expected = f"Bearer {token}".encode("ascii")

    class Handler(BaseHTTPRequestHandler):
        server_version = "DingDingMe/1"

        def log_message(self, _format: str, *_args: object) -> None:
            return

        def do_POST(self) -> None:  # noqa: N802
            if self.path != "/notify":
                self.send_error(404)
                return
            if self.headers.get("Content-Length", "0") != "0":
                self.send_error(413)
                return
            supplied = self.headers.get("Authorization", "").encode("ascii", "ignore")
            if not hmac.compare_digest(supplied, expected):
                self.send_error(401)
                return

            try:
                launch_notification()
            except OSError:
                self.send_error(503)
                return

            self.send_response(202)
            self.send_header("Content-Length", "0")
            self.send_header("Connection", "close")
            self.end_headers()

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.daemon_threads = True
    print(f"Ding Ding Me relay listening on 127.0.0.1:{args.port}", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
