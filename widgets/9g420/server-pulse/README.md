# Server Pulse

A read-only, seven-language dashboard for a Linux server. It reads CPU, memory, disk, network, power, service, and uptime data through a pinned SSH connection.

## Network paths

Set the server's Tailscale hostname or address in **TAILNET HOST OR IP**. The optional **HOME LAN HOST OR IP** is tried first, so the widget can connect directly while the phone and server share a home network. If that address cannot connect, it falls back to the Tailscale address. The connection settings screen shows which route supplied the latest readings.

The LAN address is a per-user setting stored by the launcher. It is not part of this widget file. Leave it empty if you do not need a direct home connection.

## Setup

1. Install the widget's declared Arch packages (`openssh` and `python`).
2. Install the `server-pulse-status` command on the server. It must print a JSON object using schema `1` with a Unix `checked_at` timestamp and the fields consumed by the widget.
3. Configure the Tailscale host, SSH user, and port in the widget's **Connection** screen. Optionally set the server's LAN IP or hostname there too.
4. Place the SSH private key at `~/.ssh/server-pulse` in the phone's Arch environment. Add and independently verify the SSH host key for each address in `~/.ssh/known_hosts` before connecting. The widget enforces strict host key checking and does not accept passwords.
5. Tap **CHECK NOW**. The overview shows the latest readings; the connection screen indicates whether LAN or Tailscale was used.

The server command and SSH account should be configured with read-only access appropriate to the metrics and services you want to expose. Do not put addresses, private keys, or other personal settings in a shared widget file.

## Update notes

### 1.6.0

- Added an optional home LAN address and try it before the Tailscale host.
- Added automatic Tailscale fallback when the LAN route is unavailable.
- Kept strict SSH host key verification and added the active route to the connection status.
