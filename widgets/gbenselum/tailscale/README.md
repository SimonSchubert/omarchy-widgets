# tailscale

Shows the Tailscale status and the devices on your tailnet.

- Header: the Tailscale logo with a green/red dot and `connected`/`disconnected`.
- Connected: the tailnet name and one row per device, each with an `ip` and a
  `host` button that copies the address to the clipboard.
- Disconnected: a button that opens the Tailscale app.

## Requirements

- **Tailscale installed and configured on the device, with the VPN running in
  the Tailscale Android app.** This widget reads the tunnel Tailscale sets up on
  Android; it cannot start or stop the VPN itself, so the `open tailscale`
  button opens the app instead of toggling the connection.
- MagicDNS enabled for device hostnames (without it, rows show IPs only).
- `iproute2` (declared in `requires`).
