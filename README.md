# plainsight

Render one Markdown file, plainly.

Pull a `.md` out of VS Code or anywhere else and read it on its own — clean, dark,
no clutter. It's a tiny local web page backed by a stdlib Python server. No build,
no dependencies, no accounts. It starts at login and stays out of your way.

- **One file at a time** — paste an absolute path, read it rendered.
- **Local only** — binds to `127.0.0.1`; nothing leaves your machine.
- **Zero overhead** — Python standard library and one Markdown script from a CDN.
- **Remembers your place** — scroll position is kept per file, even across a refresh.

---

## Install

One command. It maps a friendly hostname and starts the viewer for you:

```bash
./install.sh
```

That's it. Open **http://plainsight:8477** and you're reading.

### What the installer does

1. Adds `127.0.0.1 plainsight` to `/etc/hosts` (asks for `sudo` once) so you get a
   real URL instead of a bare IP and port.
2. Installs a launchd agent that runs the server, restarts it if it crashes, and
   starts it again every time you log in.

### Want a different name or a cleaner URL?

```bash
HOST=notes ./install.sh        # http://notes:8477
PORT=80    ./install.sh         # http://plainsight  (no port; installs a root agent)
HOST=md PORT=80 ./install.sh    # http://md
```

---

## Use it

1. Open your URL (**http://plainsight:8477**).
2. Paste the absolute path of a Markdown file into the box — e.g.
   `/Users/you/notes/spec.md` — and hit **Open**.
3. Read. The **↻** button re-renders the file after you edit it, keeping your spot.

The last file you opened comes back automatically next time.

### Tip: bookmark it

Add **http://plainsight:8477** to your browser bookmarks bar. One click and your
last-read file is right there — the fastest way to glance at notes while you work.

---

## Stop / uninstall

```bash
./stop.sh         # stop the running server
./uninstall.sh    # remove the launchd agent and the /etc/hosts line
```

---

## How it works

- `server.py` — a ~100-line stdlib HTTP server. Serves the page and a
  `/raw?path=<abs-path>` endpoint that returns a local file's bytes.
- `index.html` — the reader. Renders Markdown with [marked](https://github.com/markedjs/marked)
  loaded from a CDN; remembers scroll position in `localStorage`.

Because it will hand out any file the server process can read, it binds to
`127.0.0.1` only and must never be exposed to the network.
