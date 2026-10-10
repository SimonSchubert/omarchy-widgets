# omarchy widgets

The widget store for [omarchy-proot](https://github.com/SimonSchubert), the Android launcher that
runs Arch Linux and draws home-screen widgets written in OWL, a small declarative widget language.

Everything in `widgets/` has been reviewed. When a pull request is merged, CI builds `index.json`
and publishes the store to GitHub Pages, where the app's **widget store** reads it. Before
installing, the app shows you every command a widget runs and every package it installs, and it
checks the download against the reviewed file's SHA-256.

## Submitting a widget

The easy way: long-press your widget on the phone and tap **publish**. Your coding agent forks
this repo with the GitHub CLI and opens the pull request for you.

By hand:

1. Fork this repo and add your widget at `widgets/<your GitHub username, lowercase>/<name>/widget.owl`.
   Names use lowercase letters, digits and dashes.
2. Give it `meta` and declare its packages:

   ```owl
   widget "disk" {
     meta { description: "Free space on the root disk"; version: "1.0"; license: "MIT"; category: "system" }
     size: 3x2
     requires { pacman: ["dua-cli"] }
     ...
   }
   ```

3. Optionally add `preview.png`, a screenshot of the tile (under 300 KB). For the store to show
   the tile in the user's own Omarchy theme, add `previews/<theme>.webp` too, one per theme (under
   100 KB each, named like `tokyo-night.webp`); the launcher's debug build makes them with
   `scripts/store-previews.sh`.
4. Check it locally: `java -jar tools/owl.jar review . widgets/<you>/<name>/widget.owl`
5. Open a pull request. The **review** check runs the same rules and writes a summary of what the
   widget runs and installs; a maintainer reviews it and merges.

The widget language is documented in [docs/LANGUAGE.md](docs/LANGUAGE.md).

## Rules

- One folder per widget, and only `widget.owl`, `preview.png`, `README.md` and `previews/<theme>.webp` in it.
- You can only add or change widgets under your own username.
- `meta` needs a `description` (10-200 characters), a `version` and a `license`. Add a `category`
  (`news`, `dev`, `productivity`, `time`, `world`, `fun`, `home` or `system`) so it shows under that tab in the store; without one it goes under "other".
- Every package the commands need goes in `requires`. CI checks that the packages exist in Arch
  and warns about programs whose package isn't declared.
- Updates raise the version. If an update changes the commands or packages, the app asks users to
  approve it again.
- No hidden or surprising behavior. Commands that pipe downloads into a shell, delete
  recursively, ask for root, decode base64 or use `eval` are flagged, and need a good reason and
  a clear description.
- No personal data: tokens, personal paths or a hard-coded location.

## What the review looks at

Widgets run shell commands inside the phone's Arch system, not with Android permissions. They
can still read and change files there, and use the network. Reviewers read every command; the
CI summary lists them all, with anything risky flagged.

## Layout

```
widgets/<author>/<name>/widget.owl    the widget
widgets/<author>/<name>/preview.png   optional screenshot
widgets/<author>/<name>/previews/     optional screenshots per Omarchy theme (<theme>.webp)
order.txt                             the order of the store
docs/LANGUAGE.md                      the widget language
w/index.html                          where a shared widget's link lands: shows it, opens the launcher
tools/owl.jar                         the checker CI runs (built from the app's owl module)
runtimes/quickshell/                  OWL for Quickshell on Linux: the same widgets, drawn
                                      by Quickshell (Omarchy Mobile's widget board uses it)
```
