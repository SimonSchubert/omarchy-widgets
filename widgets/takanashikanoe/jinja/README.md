# jinja

A torii gate standing in the sunset sea, drawn as animated colored block glyphs —
the look of terminal ASCII art, rendered by a GPU fragment shader instead of text.

Waves drift, ripples spread around the pillars, foam blinks on the rocks and gulls
cross the sky. The 96×54 block grid, palette quantization and per-cell block-level
filling mirror the generator of the ASCII artwork **"sea torii sunset"** by
**Streider** on [ascii-magic.com](https://www.ascii-magic.com/ascii/sea-torii-sunset);
the shader is an original port written for Omalauncher.

## Tap to configure

Tapping the tile opens a settings screen:

- ▶ play / ⏸ pause (a paused widget stops its frame clock entirely)
- 24 fps switch (throttles the animation to 24 fps)
- brightness, contrast (0–200, 100 = neutral)
- RGB color-tint filter (0–200 each, 100 = neutral)
- black-color replacement: recolors near-black cells (the sky, silhouettes, deep sea)
  to a chosen hue, with strength — plus one-tap presets (Black→Blue / Green / Red, Black off)
- hue rotation of the whole palette
- a reset button; every setting persists

All labels follow the phone's locale: Japanese when it starts with `ja`, English otherwise.

The shader draws each cell as the original generator does: a 2×2 averaged sample,
nearest palette color, bottom-aligned block glyph fill — so thin structures stay solid.

## Notes

- No shell commands, no network, no packages: it is pure drawing.
- The visual design is derivative of Streider's ASCII artwork (attribution above);
  the code is MIT.
