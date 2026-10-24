# Server Pulse

A read-only Omarchy widget that each user configures to monitor a Linux server they own or are authorized to access over a private network. Every installation starts with a blank server address, optional LAN address, and SSH username; the widget queries only the SSH target entered by the user. Project author: 9G420. It has a 2×2 compact tile, a 4×4 summary, seven localized detail sections, and a state-change list. It uses the launcher's current theme and system mono font. The tile and detail screen use a small server-rack display driven by real CPU, memory, and disk readings; RX and TX lights move only when consecutive server snapshots show traffic. When both are configured, SSH tries an optional LAN address first and falls back to the tailnet host. OWL store packages contain one `widget.owl`, so this widget cannot bundle the prototype's custom pixel font.

Languages: English, Simplified Chinese, Spanish, German, French, Japanese, and Korean.

## Release notes

### v1.6.0 — 2026-10-16

- Added an optional home-LAN host or IP. The widget tries it first with a short connection timeout, then falls back to the configured tailnet host.
- Added a route indicator in Connection so the latest snapshot shows whether it used the LAN or Tailscale address.
- Validated both addresses before use and kept strict SSH host-key checking, key-only authentication, forwarding disabled, and bounded connection timeouts on each route.
- Kept all compact 2×2 readings visible by placing disk and battery values on one line.

### v1.5.1 — 2026-10-15

- Added a localized quick-setup checklist in Connection and generalized the host and display-name hints for users monitoring their own private Linux servers.

### v1.5.0 — 2026-10-15

- Added a live server-rack view to the compact tile and detail screen. Its three bays show measured CPU, memory, and root-disk use; a brief highlight marks each valid new snapshot.
- Replaced traffic history lines with directional RX/TX channels. Their lights move only when the latest pair of remote byte counters measures traffic, and their speed follows the sampled rate. Zero traffic, missing counters, stale data, and failed connections do not create motion.
- Reduced the polling interval from 60 to 20 seconds. Rates compare consecutive remote snapshots, and the traffic alert now requires five distinct valid samples above the configured limit.
- Improved small-screen spacing, label contrast, and detail-card hierarchy. The Motion setting also controls the snapshot highlight, traffic lights, and meter transitions.
- Kept the saved connection fields, strict SSH host-key checks, seven languages, and declared `openssh`/`python` dependencies.

### v1.4.0 — 2026-10-15

- Rebuilt the compact tile around CPU and memory readings, short status, and battery level. Larger tiles keep disk, network, uptime, and measured history according to available space.
- Replaced nested dashboard borders and oversized navigation buttons with fixed tabs, a section heading, aligned metric cards, and separate labels and values.
- Made traffic graphs scale to their measured history and show their range and units. This changes graph display only; the alert threshold stays independent.
- Kept existing persisted connection settings, dedicated SSH identity, strict host-key checks, seven languages, and theme colors.
- This was a local development version, superseded by v1.5.0 before publication.

### v1.3.1 — 2026-10-15

- Reworked the overview and detail pages with aligned metric cards and the active Omarchy theme palette. Resource meters now name the CPU, memory, and disk values they show.
- Replaced the power page's unclear trace with battery level and progress, external-power connection state, battery power in watts, and temperature.
- Made the event list explain each recorded state transition, timestamp, and detected cause, including CPU, memory, disk, traffic, service, and SSH connection issues.
- Kept network rates tied to received server snapshots and made unavailable or stale readings explicit.
- Colored the overview uptime value with the theme's bright green when its reading is current.

## What it reads

The widget asks the remote account to run the fixed `server-pulse-status` command over OpenSSH every 20 seconds. It shows CPU, memory, root disk, uptime, Linux network byte counters and sampled rate, SSH response time, optional power/battery/temperature sensors, and only explicitly configured services. Missing or stale values are shown as unknown, offline, or stale. Virtual machines and containers report the Linux guest's available values, not necessarily the physical host's network or power state. If both addresses are set, connection attempts use the LAN address first and the tailnet host as fallback; the latest route appears in Connection.

Traffic alerts use a 150 Mb/s threshold by default and require five consecutive valid sample intervals above it. This is a volume threshold, not intrusion detection. CPU, memory, and disk bars use the latest server snapshot. The RX/TX display uses byte-counter differences between consecutive snapshots and labels each interval-average rate in B/s, K/s, or Mb/s. A zero-rate sample has no moving light; missing counters show `--`. The brief snapshot highlight appears only after a valid update. Motion can be disabled in Connection, and no component-side random data is generated.

## Validation note

The OWL review lists the declared `openssh` and `python` packages and two commands, with no warnings. The embedded Python client is read from standard input; the configured tailnet host, optional LAN host, username, and port remain validated and passed as separate shell-quoted arguments with `sh()`. Strict host-key checking stays enabled for both routes.

## Server-side collector

The widget runs a fixed `server-pulse-status` SSH command every 20 seconds. Install this read-only Python 3 collector on the Linux server; it uses only the Python standard library and Linux kernel interfaces. The collector reads no application files, credentials, logs, or user data. Running it without an optional service allowlist requires no `sudo` or special group membership.

Save the source below on the server as `server-pulse-status.py`. Then install it and create its restricted account:

```sh
sudo install -o root -g root -m 0755 server-pulse-status.py /usr/local/libexec/server-pulse-status.py
sudo useradd --system --create-home --home-dir /var/lib/server-pulse --shell /bin/sh serverpulse
sudo passwd --lock serverpulse
sudo install -d -o root -g root -m 0755 /etc/server-pulse
printf '[]\n' | sudo tee /etc/server-pulse/services.json >/dev/null
sudo chown root:root /etc/server-pulse/services.json
sudo chmod 0644 /etc/server-pulse/services.json
sudo install -d -o serverpulse -g serverpulse -m 0700 /var/lib/server-pulse/.ssh
```

Install only the phone's public key in `/var/lib/server-pulse/.ssh/authorized_keys`, with this forced command and the key's actual public-key line:

```text
restrict,command="/usr/local/libexec/server-pulse-status.py" ssh-ed25519 AAAA... server-pulse
```

Then set the key file's owner and mode:

```sh
sudo chown serverpulse:serverpulse /var/lib/server-pulse/.ssh/authorized_keys
sudo chmod 0600 /var/lib/server-pulse/.ssh/authorized_keys
```

Use a password-locked account with no other keys, supplementary groups, `sudo` rules, or Docker socket access. Confirm the server's OpenSSH supports the `restrict` option. Do not change global SSH authentication settings for this widget. Optional service checks are configured by an administrator in `/etc/server-pulse/services.json`; use generic service labels and no personal or customer details. The allowlist supports up to eight systemd units.

<details>
<summary>Read-only collector source</summary>

```python
#!/usr/bin/env python3
"""Emit a small, read-only server status snapshot for Server Pulse."""

import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

SCHEMA = 1
SERVICE_CONFIG = Path("/etc/server-pulse/services.json")
MAX_SERVICES = 8
MAX_CONFIG_BYTES = 16 * 1024
SERVICE_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.@:-]{0,127}\.service$")


def read_text(path):
    try:
        with Path(path).open("r", encoding="ascii") as stream:
            return stream.read(4096).strip()
    except (OSError, UnicodeError):
        return None


def number(value, minimum=None, maximum=None):
    try:
        result = float(value)
    except (TypeError, ValueError, OverflowError):
        return None
    if not math.isfinite(result):
        return None
    if minimum is not None and result < minimum:
        return None
    if maximum is not None and result > maximum:
        return None
    return result


def uptime_seconds():
    raw = read_text("/proc/uptime")
    fields = raw.split() if raw else []
    value = number(fields[0], 0) if fields else None
    return int(value) if value is not None else None


def load_1m():
    raw = read_text("/proc/loadavg")
    fields = raw.split() if raw else []
    return number(fields[0], 0) if fields else None


def memory():
    raw = read_text("/proc/meminfo")
    if raw is None:
        return {"total_bytes": None, "available_bytes": None, "used_percent": None}
    values = {}
    for line in raw.splitlines():
        fields = line.split()
        if len(fields) >= 2 and fields[0].rstrip(":") in ("MemTotal", "MemAvailable"):
            parsed = number(fields[1], 0)
            if parsed is not None:
                values[fields[0].rstrip(":")] = int(parsed * 1024)
    total = values.get("MemTotal")
    available = values.get("MemAvailable")
    used = None
    if total and available is not None:
        used = round(max(0, min(100, (total - available) * 100 / total)), 1)
    return {"total_bytes": total, "available_bytes": available, "used_percent": used}


def cpu_counters():
    raw = read_text("/proc/stat")
    if not raw:
        return None
    first = raw.splitlines()[0].split()
    if not first or first[0] != "cpu":
        return None
    values = [number(field, 0) for field in first[1:]]
    if len(values) < 4 or any(value is None for value in values):
        return None
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    # guest and guest_nice are already included in user and nice counters.
    return sum(values[:8]), idle


def cpu_percent():
    before = cpu_counters()
    if before is None:
        return None
    time.sleep(0.12)
    after = cpu_counters()
    if after is None:
        return None
    total = after[0] - before[0]
    idle = after[1] - before[1]
    if total <= 0 or idle < 0:
        return None
    return round(max(0, min(100, (total - idle) * 100 / total)), 1)


def default_interface():
    raw = read_text("/proc/net/route")
    if not raw:
        return None
    for line in raw.splitlines()[1:]:
        fields = line.split()
        if len(fields) > 3 and fields[1] == "00000000":
            try:
                if int(fields[3], 16) & 1:
                    return fields[0]
            except ValueError:
                continue
    return None


def network():
    interface = default_interface()
    if not interface or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,32}", interface):
        return {"interface": None, "rx_bytes": None, "tx_bytes": None, "link_mbps": None}
    raw = read_text("/proc/net/dev")
    if not raw:
        return {"interface": interface, "rx_bytes": None, "tx_bytes": None, "link_mbps": None}
    counters = None
    for line in raw.splitlines()[2:]:
        if ":" not in line:
            continue
        name, values = line.split(":", 1)
        if name.strip() != interface:
            continue
        fields = values.split()
        if len(fields) >= 9:
            rx, tx = number(fields[0], 0), number(fields[8], 0)
            if rx is not None and tx is not None:
                counters = {"rx_bytes": int(rx), "tx_bytes": int(tx)}
        break
    speed = number(read_text(Path("/sys/class/net") / interface / "speed"), 1, 1000000)
    return {
        "interface": interface,
        "rx_bytes": counters.get("rx_bytes") if counters else None,
        "tx_bytes": counters.get("tx_bytes") if counters else None,
        "link_mbps": int(speed) if speed is not None else None,
    }


def power():
    root = Path("/sys/class/power_supply")
    external = []
    batteries = []
    try:
        supplies = list(root.iterdir())
    except OSError:
        supplies = []
    for supply in supplies:
        kind = read_text(supply / "type")
        if kind in ("Mains", "USB", "USB_C", "USB_PD"):
            online = number(read_text(supply / "online"), 0, 1)
            if online is not None:
                external.append(bool(online))
        elif kind == "Battery":
            capacity = number(read_text(supply / "capacity"), 0, 100)
            status = read_text(supply / "status")
            power_raw = number(read_text(supply / "power_now"), -100000000, 100000000)
            watts = abs(power_raw) / 1000000 if power_raw is not None else None
            if watts is None:
                current = number(read_text(supply / "current_now"), -100000000, 100000000)
                voltage = number(read_text(supply / "voltage_now"), 0, 100000000)
                if current is not None and voltage is not None:
                    watts = abs(current * voltage) / 1000000000000
            batteries.append({
                "percent": round(capacity, 1) if capacity is not None else None,
                "state": status.lower() if status in ("Charging", "Discharging", "Full", "Not charging") else "unknown",
                "power_w": round(watts, 2) if watts is not None else None,
            })
    external_state = any(external) if external else None
    battery = batteries[0] if batteries else {"percent": None, "state": "unknown", "power_w": None}
    return {"external_power": external_state, "battery_percent": battery["percent"],
            "battery_state": battery["state"], "battery_power_w": battery["power_w"]}


def temperature_c():
    values = []
    root = Path("/sys/class/thermal")
    try:
        zones = list(root.glob("thermal_zone*/temp"))
    except OSError:
        zones = []
    for path in zones[:32]:
        # Some virtualized Linux environments expose a battery pseudo-zone with a sentinel 0 value.
        # That is not a CPU/system temperature and must remain unknown.
        zone_type = read_text(path.parent / "type")
        if zone_type and "battery" in zone_type.lower():
            continue
        value = number(read_text(path), -100000, 200000)
        if value is not None:
            # Most Linux thermal-zone values use millidegrees Celsius.
            if abs(value) > 1000:
                value /= 1000
            if -20 <= value <= 130:
                values.append(value)
    return round(max(values), 1) if values else None


def services():
    try:
        with SERVICE_CONFIG.open("rb") as stream:
            raw = stream.read(MAX_CONFIG_BYTES + 1)
        if len(raw) > MAX_CONFIG_BYTES:
            return []
        config = json.loads(raw.decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return []
    if not isinstance(config, list):
        return []
    result = []
    for item in config[:MAX_SERVICES]:
        if not isinstance(item, dict):
            continue
        name, unit = item.get("name"), item.get("unit")
        expected = item.get("expected", "active")
        if (not isinstance(name, str) or not name or len(name) > 48
                or not isinstance(unit, str) or not SERVICE_NAME.fullmatch(unit)
                or expected not in ("active", "inactive")):
            continue
        status = "unknown"
        try:
            completed = subprocess.run(
                ["systemctl", "--no-pager", "is-active", "--", unit],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, timeout=1.0, check=False,
            )
            candidate = completed.stdout.strip()
            if candidate in ("active", "inactive", "failed"):
                status = candidate
        except (OSError, subprocess.TimeoutExpired):
            pass
        result.append({"name": name, "status": status, "expected": expected,
                       "healthy": status == expected})
    return result


def snapshot():
    usage = None
    try:
        disk = shutil.disk_usage("/")
        usage = {"total_bytes": disk.total, "free_bytes": disk.free,
                 "used_percent": round((disk.total - disk.free) * 100 / disk.total, 1) if disk.total else None}
    except OSError:
        usage = {"total_bytes": None, "free_bytes": None, "used_percent": None}
    return {
        "schema": SCHEMA,
        "checked_at": int(time.time()),
        "uptime_seconds": uptime_seconds(),
        "load_1m": load_1m(),
        "cpu_percent": cpu_percent(),
        "memory": memory(),
        "root_disk": usage,
        "network": network(),
        "power": power(),
        "temperature_c": temperature_c(),
        "services": services(),
    }


if __name__ == "__main__":
    print(json.dumps(snapshot(), ensure_ascii=False, separators=(",", ":"), allow_nan=False))
```

</details>

The collector prints one versioned JSON snapshot. Missing sensors are `null`; a virtual machine or container may report only guest-level network and sensor values. Test it as the restricted account before configuring the widget:

```sh
sudo -u serverpulse /usr/local/libexec/server-pulse-status.py
```

## Connect to your server

Configure the widget with a Linux server you own or are authorized to monitor. No server address or account is built in, and the widget does not contact a project or maintainer server. The phone and your server must have a private network route between them. Tailscale is one option; another VPN or private network also works. With Tailscale, install the official app on Android and sign in to the same tailnet as your server. Exit Node is not needed for access to a server on that tailnet. The widget never asks for a VPN password, login token, or auth key. If you set both addresses, it tries the optional home-LAN address first and uses the tailnet host when the LAN route cannot connect.

1. On the Linux server, install the read-only collector and create its restricted SSH account using the self-contained instructions in **Server-side collector** above. The server needs an SSH service reachable from the phone on the port you will enter below.
2. In the phone's Omarchy Linux terminal, create a dedicated key and protect its directory. If `~/.ssh/server-pulse` already exists, keep using it; do not overwrite it:

   ```sh
   install -d -m 0700 ~/.ssh
   ssh-keygen -t ed25519 -N '' -f ~/.ssh/server-pulse -C server-pulse
   chmod 0600 ~/.ssh/server-pulse
   ```

3. Transfer only `~/.ssh/server-pulse.pub` to the server administrator through a trusted method. Install it in `/var/lib/server-pulse/.ssh/authorized_keys` as shown above. Keep `~/.ssh/server-pulse` private on the phone; never upload or share it.
4. Ask the server administrator to obtain the Ed25519 host-key fingerprint through a trusted channel. On a typical Linux server, it is:

   ```sh
   sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256
   ```

   On the phone, fetch and inspect the candidate key for each address you plan to use, replacing `SERVER_ADDRESS` and `SSH_PORT` with that address and the server's SSH port:

   ```sh
   ssh-keyscan -t ed25519 -p SSH_PORT SERVER_ADDRESS 2>/dev/null | ssh-keygen -lf - -E sha256
   ```

   Compare the displayed fingerprint with the value obtained through the trusted channel. Only if they match, add the key to the phone's `known_hosts`:

   ```sh
   ssh-keyscan -H -t ed25519 -p SSH_PORT SERVER_ADDRESS 2>/dev/null >> ~/.ssh/known_hosts
   chmod 0600 ~/.ssh/known_hosts
   ```

   Never accept an unknown or changed host key in the widget.
5. Before opening the widget, test that the phone key returns one JSON line. Replace the address and port with the same values used above:

   ```sh
   ssh -T -i ~/.ssh/server-pulse -p SSH_PORT -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes serverpulse@SERVER_ADDRESS
   ```

6. Open **Connection** in the widget. Enter your server's tailnet host or IP, restricted SSH username (created by the server setup, `serverpulse` by default), and SSH port (usually `22`), then optionally enter that same server's home-LAN host or IP. Verify and add both host keys to `~/.ssh/known_hosts` before using both routes. Set a display name if desired. The widget uses `~/.ssh/server-pulse`, requires public-key authentication and strict host-key checking, disables forwarding, bounds connection time, and hides raw SSH diagnostics.

Do not configure router port forwarding or expose SSH, a web panel, WebSocket, or Docker API to the public Internet. If using Tailscale, restrict tailnet policy to the intended phone identity and this status account; apply an equivalent access rule with other VPNs.

Before relying on a server connection, verify that the phone can reach its SSH port over the private network and that the restricted account cannot obtain a shell, use `sudo`, access Docker, or read unrelated files. Virtual machines and containerized servers may report only guest-level network and sensor values.
