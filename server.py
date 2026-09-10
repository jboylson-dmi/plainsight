#!/usr/bin/env python3
"""plainsight — minimal always-on markdown viewer. Stdlib only.

Serves index.html and a /raw?path=<abs-path> endpoint that returns the raw
bytes of any local file so the browser can render it with marked (CDN).
Binds to 127.0.0.1 ONLY — it will hand out any file the process can read,
so it must never be reachable from the network.
"""
import atexit
import http.server
import os
import signal
import subprocess
import sys
import urllib.parse

HOST = "127.0.0.1"
PORT = int(os.environ.get("PLAINSIGHT_PORT", "8477"))
HERE = os.path.dirname(os.path.abspath(__file__))
PID_FILE = os.path.join(HERE, "PID.txt")


def notify(title, msg):
    """Best-effort macOS desktop notification; never fatal."""
    try:
        subprocess.run(
            ["osascript", "-e", f'display notification "{msg}" with title "{title}"'],
            check=False, timeout=5,
        )
    except Exception:
        pass


def write_pid():
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))


def clear_pid():
    try:
        os.remove(PID_FILE)
    except FileNotFoundError:
        pass


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass  # quiet

    def _send(self, code, body, ctype="text/plain; charset=utf-8"):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/" or parsed.path == "/index.html":
            with open(os.path.join(HERE, "index.html"), "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8")
        if parsed.path == "/raw":
            qs = urllib.parse.parse_qs(parsed.query)
            path = (qs.get("path") or [""])[0]
            path = os.path.expanduser(path)
            if not path or not os.path.isabs(path):
                return self._send(400, "Provide an absolute file path.")
            if not os.path.isfile(path):
                return self._send(404, f"Not found: {path}")
            try:
                with open(path, "rb") as f:
                    return self._send(200, f.read(), "text/plain; charset=utf-8")
            except Exception as e:
                return self._send(500, f"Read error: {e}")
        return self._send(404, "Not found")


def main():
    write_pid()
    atexit.register(clear_pid)

    def _bye(signum, frame):
        notify("plainsight", "stopped")
        clear_pid()
        sys.exit(0)

    signal.signal(signal.SIGTERM, _bye)
    signal.signal(signal.SIGINT, _bye)

    try:
        httpd = http.server.ThreadingHTTPServer((HOST, PORT), Handler)
    except OSError as e:
        notify("plainsight", f"failed to start: {e}")
        clear_pid()
        print(f"failed to start: {e}", file=sys.stderr)
        sys.exit(1)

    notify("plainsight", f"started on http://{HOST}:{PORT}")
    print(f"plainsight on http://{HOST}:{PORT}  (pid {os.getpid()})")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
