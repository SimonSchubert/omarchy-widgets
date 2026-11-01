# SolarEdge

Home tile for a SolarEdge site. It shows the latest power, today's energy, and the last 12 hours. Open it for the peak, this month, lifetime, and battery or grid when the site has them.

The picture is sample data: 4.2 kW, 18.4 kWh today, a made-up curve. It is not a reading from a real site.

## Sign in

Create a Site Access app at [developer.solaredge.com](https://developer.solaredge.com/) with `SITE_DATA` and `DEVICE_DATA`. Set its redirect URI to `http://127.0.0.1:8734/callback`. The portal rejects the name `localhost`. That address is the phone itself, so after you approve, the browser hands the approval straight back to setup. Nothing to copy out of the address bar. The site id is the number in the monitoring address, after `/site/`. Setup asks for the site id, client id and client secret, and keeps them if you press enter.

The token never goes in this file. It stays in `~/.config/omarchy-solaredge/auth.json` (mode 600). SolarEdge replaces the refresh token on every use, and the reader writes the new one back before it asks for readings. Setup uses a random OAuth `state` and rejects callbacks that do not match.

## Side note for building

Store path: `widgets/jenskock/solaredge/widget.owl`. The folder name is the GitHub login, lowercase, then a name of lowercase letters, digits and dashes. The folder holds only `widget.owl`, `preview.png` and this README.

The reader is inlined. On first run it installs `~/.local/bin/solaredge-sync`, so that name is not an Arch package. `curl`, `jq` and `python` are. Setup listens on `127.0.0.1:8734` and opens the approval page with `xdg-open`, which is the launcher's browser bridge, not a package. Readings are `~/.config/omarchy-solaredge/data.json`, which the tile reads directly. A `details` or `force` file in that directory asks for the extra figures; the 45-minute poll is an ordinary sync. A companion usage tile can share the same login and `data.json` later; this PR is only the production tile.

Review notes that are expected:

- `base64` builds the HTTP Basic header from the client id and secret. It does not decode a download.
- `chmod 700` is the config directory, `chmod 600` the token file, and `chmod 755` the installed reader.
- Token exchange and API calls put Authorization headers in a curl `-K` config file (mode 600), not on the process argv.

Cloud samples are 15 minutes apart. Quarter-hour series cover at most 12 hours. One poll reads production power, the overview for today's production and consumption, and meter telemetry for the consumption curve. Between 21:00 and 05:00 a day already fetched is kept and production is shown as 0, which stays inside the free tier.

## License

MIT
