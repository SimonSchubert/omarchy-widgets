# tailscale

Shows the Tailscale status and the devices on your tailnet.

- Header: the Tailscale mark, a green/red dot, and `connected`, `disconnected`,
  `reconnecting…`, or the number of devices (`6 peers`).
- Connected: the tailnet name and one row per device, sorted by name. Each row
  has the device's name, its IP below it, and compact `ip` / `host` labels that
  copy either to the clipboard. The list scrolls, and the layout fits the
  smallest size (3x4).
- If only this device is online, the tile shows this device's name and IP and
  `No peers seen.`
- When Tailscale rebuilds the tunnel (it renames the `tun` interface and
  reinstalls the device routes), the routes disappear for a moment. The header
  then says `reconnecting…` and the last known device list stays, instead of
  dropping to `No peers seen.` The list is kept across restarts.
- Disconnected: a button that opens the Tailscale app.

## Requirements

- **Tailscale installed and configured on the device, with the VPN running in
  the Tailscale Android app.** This widget reads the tunnel Tailscale sets up on
  Android; it cannot start or stop the VPN itself, so the `open app` button
  opens the app instead of toggling the connection.
- MagicDNS enabled for device hostnames (without it, rows show IPs only).
- `iproute2` and `bind` (declared in `requires`). Names are resolved through
  the guest resolver first, falling back to asking MagicDNS (100.100.100.100)
  directly, so hostnames work even before the launcher publishes the phone's
  real network DNS (omalauncher#20).
