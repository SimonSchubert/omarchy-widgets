# jinja

A torii gate standing in the sunset sea, drawn as animated colored block glyphs —
the look of terminal ASCII art, rendered by a GPU fragment shader instead of text.

Waves drift, ripples spread around the pillars, foam blinks on the rocks and gulls
cross the sky. The 96×54 block grid, palette quantization and per-cell block-level
filling mirror the generator of the ASCII artwork **"Sea Torii Sunset"** from
[ascii-magic.com](https://www.ascii-magic.com/ascii/sea-torii-sunset)
(source: [kailashsr38/ascii-magic-art](https://github.com/kailashsr38/ascii-magic-art));
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

## License

The visual design is derivative of the ASCII artwork "Sea Torii Sunset", which is
MIT licensed:

> Copyright (c) 2026 ASCII Magic (ascii-magic.com)
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

The full license text is quoted verbatim above (kept in this README, since the
store widget folder holds only widget.owl, preview.png and README.md). The shader
code in `widget.owl` is my own work and is offered under the same MIT terms.

## Notes

- No shell commands, no network, no packages: it is pure drawing.
