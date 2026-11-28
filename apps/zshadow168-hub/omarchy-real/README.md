# Omarchy Real

A launcher app for a nested Hyprland + Omarchy session. It does not ship a compositor or a shell
build: you need a nested-capable Hyprland and Omarchy shell installed on the phone. The two scripts
below make the app work with any such install, without personal paths in the app file.

Save them as `session.sh` and `screensaver.sh` under `$HOME/.local/share/omarchy-real/`, make them
executable, and enter their **absolute** paths (expand `$HOME` yourself) in the app's two fields.
The app saves those paths on the phone only.

## Protocol the app expects

All files live in `$XDG_RUNTIME_DIR/omarchy-real/` (falling back to `/run/user/$(id -u)`).

| File | Written by | Meaning |
| --- | --- | --- |
| `session.pid` | `session.sh` | PID of the detached session. It must be a process-group leader (start it with `setsid`), so stopping sends `SIGTERM` to `-PID` and takes only that session's children with it. |
| `session.socket` | `session.sh` | Name of the nested Wayland socket inside `$XDG_RUNTIME_DIR`, e.g. `wayland-1`. Status is "running" only while the PID is alive **and** this socket exists. |
| `saver.pid` | `screensaver.sh` | PID of the detached screensaver process group, stopped the same way. |

The app never uses `pgrep`/`pkill` patterns or kills other users of `quickshell`, `swaybg` or
`hyprland`. Stopping asks for confirmation first.

## `session.sh`

Replace `PREFIX` (or set `OMARCHY_REAL_PREFIX`) with the root of your nested install; it must
contain `bin/Hyprland` and `etc/hypr/hyprland.lua`.

```sh
#!/bin/bash
set -euo pipefail
R=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
D=$R/omarchy-real
mkdir -p "$D"

# Detach once so the session survives the terminal or agent that launched it.
if [ "${OMARCHY_REAL_DETACHED:-}" != 1 ]; then
  export OMARCHY_REAL_DETACHED=1
  setsid nohup "$0" "$@" >"$D/session.log" 2>&1 </dev/null &
  echo $! > "$D/session.pid"
  exit 0
fi

# Replace only a session this script started before, never other processes.
old=$(cat "$D/session.pid" 2>/dev/null || true)
if [ -n "$old" ] && [ "$old" != "$$" ] && kill -0 "$old" 2>/dev/null; then
  kill -TERM -- -"$old" 2>/dev/null || true
  sleep 1
fi
echo $$ > "$D/session.pid"

# The socket name your compositor creates inside $XDG_RUNTIME_DIR.
SOCKET=wayland-1
printf '%s\n' "$SOCKET" > "$D/session.socket"

PREFIX=${OMARCHY_REAL_PREFIX:-$HOME/.local/share/omarchy-real}
export OMARCHY_PATH=$PREFIX/share/omarchy
export PATH=$PREFIX/bin:$OMARCHY_PATH/bin:$PATH
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export QT_QPA_PLATFORM=wayland
export QT_QUICK_BACKEND=software
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export HYPRLAND_EGL_SURFACELESS=1
export AQ_NO_KMS_REQUIREMENT=1

exec "$PREFIX/bin/Hyprland" --i-am-really-stupid \
  -c "$PREFIX/etc/hypr/hyprland.lua" "$@"
```

## `screensaver.sh`

It uses the socket name recorded by `session.sh` and stops only its own process group.

```sh
#!/bin/bash
set -euo pipefail
R=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
D=$R/omarchy-real
mkdir -p "$D"

if [ "${OMARCHY_REAL_SAVER_DETACHED:-}" != 1 ]; then
  export OMARCHY_REAL_SAVER_DETACHED=1
  setsid nohup "$0" "$@" >"$D/saver.log" 2>&1 </dev/null &
  echo $! > "$D/saver.pid"
  exit 0
fi

echo $$ > "$D/saver.pid"
export XDG_RUNTIME_DIR=$R
export WAYLAND_DISPLAY=$(cat "$D/session.socket" 2>/dev/null || printf wayland-1)
PREFIX=${OMARCHY_REAL_PREFIX:-$HOME/.local/share/omarchy-real}
export OMARCHY_PATH=$PREFIX/share/omarchy
export PATH=$PREFIX/bin:$OMARCHY_PATH/bin:$PATH
exec omarchy-launch-screensaver force
```

Packages: `util-linux` provides `setsid`. The nested compositor, its config and the Omarchy shell
are supplied by your own install, not by this app.
