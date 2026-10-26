# omatv remote

A remote for an Android TV or Google TV box, over the remote-control service the TV
already runs (`_androidtvremote2._tcp`) — the same channel the phone's own remote app
uses. No ADB, no developer options, no account, and nothing on the TV to install.

## What it shows

- **The tile** (6x3, minimum 4x3) — what the TV is doing, and the five keys worth a tap
  without opening anything: power, volume up, volume down, play/pause and mute.
- **The view** (tap the tile) — the whole remote: the pad with its centre key, back,
  home, recents, channels, transport, volume, a text box for typing into a field on the
  TV, and the switches.
- The play/pause key turns itself over as you tap it. The TV does not report playback
  over this service, so the symbol is what you last asked for, and goes back to play
  when the TV moves to another app or wakes.
- Two layouts, `simple` and `full`, and volume by either thumb, so the remote fits the
  hand holding the phone. Keys a TV only answers in some apps draw outlined, and the
  line at the bottom names what the app in front ignores.

## Pairing

Type the TV's address and tap `pair` — the network page in the TV's own settings shows
it, as does your router's list of connected devices. The TV then shows a code; type
that into the field that appears and send. This is once per TV: the client certificate
and the address stay on the phone, and every later tap reuses them. To start over,
`python3 ~/.local/share/omatvremote/tvremote.py forget`.

## Where it keeps itself

The widget is one file. Its first run writes what it needs into
`~/.local/share/omatvremote` — the client, two helpers, a click sound and the copy of
the protocol library the client imports — and rewrites those only when the widget's own
copy changes, which a small tag file holds the hash of. Nothing is downloaded, nothing
is installed with pip, and each file the installer writes is mode 600.

Keys go through a small daemon that keeps one connection open, so a tap costs a write
to a pipe rather than a TLS handshake. It starts itself when the widget first asks for
the TV's state, reconnects with backoff while the TV sleeps, and writes one line per
command to `~/.local/share/omatvremote/log`, kept under 32 KB. `tvremote.py stop` ends
it, and the widget starts it again when it needs it.

## Privacy

- The TV's address is kept in the widget's state and in that folder, and goes only to
  the TV itself, on ports 6466 and 6467 of the address you type. No other host is
  contacted.
- The pairing's private key is written by the client and never read by the widget's own
  commands.
- The text box types into whatever field is open on the TV, which can be a password.
  What you type is never shown in the widget and never written to the log: the log
  records `text (13 chars)`.
- The widget holds no account, no token and no location. Nothing personal is in this
  file: the only address in it is `192.168.0.123`, an example in a docstring.

## Requirements

The `requires` packages are what the protocol library imports and the helpers call:
`python`, `python-cryptography`, `python-protobuf`, `python-aiofiles` and `procps-ng`
(for `pgrep`).

`androidtvremote2` is vendored inside the widget file so that the whole thing ships as
one `.owl`. It is Copyright Joseph Wynn, licensed under the Apache License 2.0
(<https://github.com/JosephWynn/python-androidtvremote2>); the only change is that its
`"""` docstrings are written `'''`, which the widget language cannot hold inside a
command.
