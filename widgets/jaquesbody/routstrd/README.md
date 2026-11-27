# routstrd

Easily control, monitor and top up your routstr usage. The tile turns red, amber or green depending on
your connection status. Every metric from `routstrd monitor` is there to see, plus detailed Logs and super
simple Lightning wallet payment via QR code or invoice.

A 1×1 tile with the routstr mark: green while routstrd runs, amber when this phone can't reach it, red
when it is down. Tap it for the full screen:

- the daemon's state with an on/off switch, then balance, 30-day spend, requests and average sats per
  request;
- **Monitor**: the overview, history chart, models, providers, clients and recent requests that
  `routstrd monitor` shows, each over all time, the last 24 hours, 7 days or 30 days;
- **Logs**: the daemon's journal;
- **Top up**: an amount, a BOLT11 invoice, its QR code and a copy button, with payment confirmation while
  the invoice is open.

## What it runs

Everything is in `widget.owl`, including the shell program that backs every button. No helper script is
installed or needed. The program is written once in the file as `agent` and filled in with a verb and
an argument for each command:

```
status | usage <window> | logs <lines> | start | stop | restart | topup <sats> | quote <operation-id>
```

- `curl` reads routstrd's loopback API at `127.0.0.1:8008`; `jq` trims the large usage reply and shapes
  the JSON the screen draws;
- `systemctl --user` starts, stops and restarts `routstrd.service`, and `journalctl --user` reads its
  log;
- `qrencode` draws the invoice's QR on the phone that is looking at the screen.

The commands run on this device when the **Host** setting is blank (how the desktop uses the widget).
Set an SSH host alias in that field to run the same program on the machine that runs routstrd instead.
For each command the widget writes the filled-in program to `~/.cache/routstrd-<verb>.sh` with
`printf %s` and runs that file; over SSH the same text goes on stdin and is written and run there. The
program is data, never a shell word, so no widget value is executed as code. If the SSH connection
fails, the phone runs the file it already wrote locally. Only the host alias, the amount and an
operation id are passed as shell words, each through `sh()`. There is no token, address, username or key
in the file.

The quote poll starts nothing while the wallet is idle: an `every 5s` block only asks the daemon about
an invoice while one is open. The status, monitor and journal sources read on their own slower
intervals, and only while their view is on screen.

## Requires

`openssh`, `coreutils`, `curl`, `jq` and `qrencode`, plus a reachable `routstrd` with a funded wallet on
the machine named in **Host** (or on this device when it is blank). Without a reachable daemon the tile
is amber and the screen shows a **Host** card for setting the alias.

## Notes

- The status colours are fixed (green `#4ade80`, amber `#fbbf24`, red `#f87171`) rather than theme names:
  some themes, hackerman among them, name their red green.
- `meta`: version 1.3, MIT, category `dev`, owl 16.
