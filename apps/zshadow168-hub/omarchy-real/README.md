# Omarchy Real

A launcher app for a nested Hyprland + Omarchy session. The app writes its own
`session.sh`, `screensaver.sh` and `hyprland.lua` into
`~/.local/share/omarchy-real/` when you tap **install / refresh default
scripts**, and its buttons always run those files. Nothing has to be copied by
hand, no personal path is entered in the app, and the exact shell that runs is
visible in `app.owl` for review.

It does not ship a compositor: that still has to be built once (see below).

## What the app runs

All files live in `$XDG_RUNTIME_DIR/omarchy-real/` (falling back to
`/run/user/$(id -u)`).

| File | Written by | Meaning |
| --- | --- | --- |
| `session.pid` | `session.sh` | PID of the detached session. It is a process-group leader (`setsid`), so stop sends `SIGTERM` to `-PID` and takes only that session's children with it. |
| `session.socket` | `session.sh` | Name of the nested Wayland socket inside `$XDG_RUNTIME_DIR`. Status is "running" only while the PID is alive **and** this socket exists. |
| `saver.pid` | `screensaver.sh` | PID of the detached screensaver group, stopped the same way. |

`session.sh` detaches once, replaces only a session it started before, picks a
free `wayland-N` socket without touching the launcher's display, and execs the
nested Hyprland with the config the app wrote. A small background watcher
creates and removes one throwaway Wayland output once IPC is up, because some
launchers never send the initial xdg configure Aquamarine waits for.
`screensaver.sh` stays alive as the process-group leader until the screensaver
foot window closes, so "running" means what is on screen. Stop/close ask for
confirmation and never use `pgrep`/`pkill` patterns.

The generated Lua config loads the real Omarchy shell when
`$OMARCHY_PATH/default/hypr/bootstrap.lua` exists; without it the nested
desktop still starts. Software rendering is the default. Set
`OMARCHY_REAL_WIDTH`, `OMARCHY_REAL_HEIGHT`, `OMARCHY_REAL_REFRESH_MHZ`,
`OMARCHY_REAL_PREFIX` or `OMARCHY_REAL_OMARCHY_PATH` in the environment only
if you need to override the defaults.

Packages declared in `requires`: `util-linux` provides `setsid`.

## Getting the nested-capable Hyprland

Arch's packaged `hyprland` cannot be used here: under omalauncher/proot
`/usr/bin/Hyprland` aborts with `CBackend::create() failed` before creating a
socket, because stock Aquamarine requires a DRM/KMS output while the launcher's
parent surface is shared-memory only. The app therefore uses a build with the
small nested-backend patches applied.

The exact, pinned recipe and the patch files are published at
**https://github.com/zshadow168-hub/omarchy-real-nested** — no manual copying
needed there either:

```sh
pacman -S --needed --noconfirm base-devel cmake ninja git hyprland jq socat foot util-linux
yay -S hypa-ttfx-bin                 # aarch64 ttfx for the screensaver effect
git clone https://github.com/zshadow168-hub/omarchy-real-nested.git
cd omarchy-real-nested
./build.sh
```

That pins Aquamarine `a79fb21b2e2a82dd061a6d071802bcf38bd5c383`, Hyprland
`5c9377c15f85c50648f35ca5a213754f95b93ca0` and Omarchy
`158e8cfb3a03f7b390e4213eaf15edcea0dfaa98`, applies the three plain `git diff`
patches in that repository, and installs into
`$HOME/.local/share/omarchy-real` with `cmake -G Ninja` and `ninja install`.
If you export `OMARCHY_REAL_PREFIX` for a different install root, export the
same value before tapping the app's launch button. After building, tap
**install / refresh default scripts** in the app.

Verify with:

```sh
sig=$(ls /run/user/0/hypr | head -1)
HYPRLAND_INSTANCE_SIGNATURE=$sig "$HOME/.local/share/omarchy-real/bin/hyprctl" monitors -j
HYPRLAND_INSTANCE_SIGNATURE=$sig "$HOME/.local/share/omarchy-real/bin/hyprctl" configerrors
```

One `WAYLAND-*` monitor at scale 1 that matches the launcher window, and no
config errors. The app's status row turns green only while its recorded PID is
alive and the recorded socket exists.
