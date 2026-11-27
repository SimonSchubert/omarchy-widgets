# opencode burn

An OpenCode usage tracker for both free and paid models. Track today's requests
at a glance, a rolling five-hour window or paid model usage in more detail.

The 2×2 tile is a gauge: watch the day's share of your free quota or your paid
model usage, plus the five-hour window inside it and a snappy verdict under it.
Two corner tags show which meter is on.

## What it shows

- the day against the cap, as a number and as a chart of when it was spent,
  split by the machine that spent it, with a projection at the current rate;
- every model's requests and tokens today, a tap on a row aims the chart at it,
  and a free/all filter for the list;
- the five-hour window of the model OpenCode is running, against its own limit;
- the paid side: the key's balance, a low-balance warning, spend over 24h, 7d,
  30d or all time, and which model spent it;
- the same balance in sats, or in GBP, USD or EUR at the last BTC rate;
- settings for three notifications — free daily, free window, paid low — and
  the provider card.

The FREE / $ pill only picks which meter the tile reads. Neither side moves your
sessions or touches your config.

## Where the numbers come from

- **This machine**: `~/.local/share/opencode/opencode.db`, read-only. Both
  schemas OpenCode has used are read, so an upgrade does not break it.
- **The free lineup and its prices**: `models.dev` and `opencode.ai/zen`, every
  two hours, cached. A model counts as free only while the catalogue prices it
  at nothing.
- **The cap**: OpenCode publishes no live quota, so the ring is measured against
  a cap you set with the slider, and it sticks. Per-model five-hour limits live
  in `~/.config/opencode-burn/limits.json`, which the Omarchy bar helper reads
  too.
- **The paid side**: the provider's own balance endpoint, every five minutes.
  The key is the one OpenCode already has, or one in
  `~/.config/opencode-burn/paid.json` (0600, written by the settings card).
- **Rates**: CoinGecko, cached for fifteen minutes.

## Other machines

A device is linked with an SSH host alias. **Copy installer** puts the
installer on the clipboard; run it in a terminal there, and it leaves a small
reader and a number for that machine's Omarchy bar. Paste what it prints back
and the device joins the chart, read over SSH every ten minutes. It reads only
that SSH user's own `~/.config/opencode/opencode.json` and `~/.routstrd`.

## Privacy

While it polls, the key never appears on a command line: it goes to the scripts
in a 0600 file, and over SSH it travels on stdin. `curl` takes the
`Authorization` header from a 0600 config, so `ps` shows neither. Nothing is
uploaded. The only requests are the model catalogue, the BTC rate, the balance
endpoint and the SSH reads above.

The one write to OpenCode's config is the **connect** button in settings, which
sets up the provider you pointed it at. There is no model switching.

## Requires

`sqlite`, `curl`, `jq`, `openssh`, `coreutils`, `gawk`, `sed`, `gzip` and
`procps-ng`, an OpenCode install on this phone, and optionally a paid provider
whose node answers the balance API.

## Notes

- The free tier is throttled ad hoc, so the ring shows what you told it to
  measure you against, not a promise.
- `meta`: version 2.0.0, MIT, category `dev`, owl 16.