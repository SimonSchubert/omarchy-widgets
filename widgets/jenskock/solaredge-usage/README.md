# SolarEdge usage

Home tile for what a SolarEdge site is using. It shows the latest consumption, today's energy, and the last 12 hours. Open it for the peak, this month, and how much came from the panels and the grid.

The picture is sample data: 1.8 kW, 9.6 kWh today, a made-up curve. It is not a reading from a real site.

## Sign in

Same Site Access app as the production tile. Set the redirect URI to `http://127.0.0.1:8734/callback`. The portal rejects the name `localhost`. That address is the phone itself, so after you approve, the browser hands the approval straight back to setup. The site id is the number in the monitoring address, after `/site/`.

If production is already connected, this tile uses that login. Connecting here signs production in too. The token never goes in this file. It stays in `~/.config/omarchy-solaredge/auth.json` (mode 600). SolarEdge replaces the refresh token on every use, and the reader writes the new one back before it asks for readings. Setup uses a random OAuth `state` and rejects callbacks that do not match.

## Side note for building

Store path: `widgets/jenskock/solaredge-usage/widget.owl`. The folder holds only `widget.owl`, `preview.png` and this README.

The reader is inlined, the same program the production widget installs at `~/.local/bin/solaredge-sync`. Either tile can install it. The marker line keeps a later run from replacing a copy that is already current. Both tiles read `~/.config/omarchy-solaredge/data.json`. `curl`, `jq` and `python` are the packages. Setup listens on `127.0.0.1:8734` and opens the approval page with `xdg-open`, which is the launcher's browser bridge, not a package.

Review notes that are expected:

- `base64` builds the HTTP Basic header from the client id and secret. It does not decode a download.
- `chmod 700` is the config directory, `chmod 600` the token file, and `chmod 755` the installed reader.
- Token exchange and API calls put Authorization headers in a curl `-K` config file (mode 600), not on the process argv.

One poll is shared. It reads production power, today's overview, and the consumption curve, at most every 45 minutes. Between 21:00 and 05:00 a day already fetched is kept and production is shown as 0. Usage then holds the last evening sample until morning, which stays inside the free tier.

## License

MIT
