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

Everything goes through one command, `routstr-ctl`, on the phone:

```
routstr-ctl status|usage <window>|logs [lines]|start|stop|restart|topup <sats>|quote <operation-id>
```

The widget carries no address, username, key or token, and every value in a command goes through `sh()`.
The store installs one `widget.owl`, so the helper isn't bundled: install your own `routstr-ctl` at
`~/.local/bin/routstr-ctl` on the phone and on the machine that runs routstrd. Its job is to hide the
difference between the two devices:

- reads ask routstrd's loopback API (`127.0.0.1:8008`), through the SSH tunnel this phone keeps to that
  machine when it is up, and over SSH when it isn't;
- start, stop, restart and the logs always go over SSH;
- the phone's copy draws the QR code locally with `qrencode` from the invoice the daemon returns, and
  shapes the 40 KB usage reply down to the few kilobytes the screen draws.

Set up an SSH host named `routstr` in `~/.ssh/config` (key-only, `BatchMode`, a short timeout), keep
routstrd on loopback, and adapt the helper to your own paths. Without the helper the screen says so; the
tile stays amber.

## Requires

The widget declares `openssh`, `coreutils`, `curl`, `jq` and `qrencode`; it also needs `routstr-ctl` and a
running `routstrd` (with its wallet) on a Linux machine this phone can reach over SSH, or through the
tunnel.

## Notes

- The status colours are fixed (green `#4ade80`, amber `#fbbf24`, red `#f87171`) rather than theme names:
  some themes, hackerman among them, name their red green.
- The quote poll runs every 5 seconds only while a top-up invoice is open; with no invoice the command is
  a no-op.
- `meta`: version 1.2, MIT, category `dev`, owl 16.
