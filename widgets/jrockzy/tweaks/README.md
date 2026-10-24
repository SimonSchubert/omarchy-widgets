# tweaks

A tweak tool for Omalauncher: every setting in `style.toml` on one screen, with quick switches on the tile.

## On the tile

- **‹ theme ›** steps through your installed Omarchy themes, with each one's colors.
- **square / soft / round** cycles the corner style, **gaps** cycles 0, 4, 8 and 12 dp, and **bar** shows or hides the status bar.
- Tap anywhere else for the full tool.

## Behind the tap

- **all settings**: every setting the launcher's style takes, with its description, current value and a control (toggle, slider, choices or color swatches). Changed ones are marked and have a "back to default" link.
- **look**: themes with their preview pictures, the theme's backgrounds, font, monochrome icons and corners.
- **home**, **bars**, **terminal & gestures**: the same settings, a group at a time. Swipe up and swipe down offer the panels in your widgets folder.
- **widgets**: your widgets, apps, faces and panels, with their errors. Remove one (it goes to `.removed/`), restore one, or add one of the launcher's examples.
- **backups**: snapshot `style.toml`, restore any `style.toml.*` backup, or reset to defaults. Restore and reset snapshot the current style first.
- **under the hood**: buttons to the launcher's own screens, and the launcher's and phone's details.

## How it works

The settings come from `defaults.toml`, so settings added in a launcher update appear on their own, with their own
descriptions. The widget writes a small Python script to `~/.cache/omalauncher-tweaks/tweaks.py` (the whole script
is in `widget.owl`) that reads the launcher's files and edits `style.toml` line by line, so its comments and order
stay as they are. It never touches `drawer.owl` or its own file.
