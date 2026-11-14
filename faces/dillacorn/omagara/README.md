# Omagara v1.6

Niagara-inspired OWL 21 home face for [Omalauncher](https://github.com/SimonSchubert/omalauncher). No extra packages or shell commands.

## Features

- **Alphabet:** Elastic A–Z navigation with app previews biased toward frequently launched apps (less aggressively near A), a letter-sized Settings cog in the shaded worm tail, distance/speed-sensitive wiggle, optional opposite-edge input, and configurable haptics.
- **Apps:** Buffered full-height browser with elastic ends, adjustable scale, padded A–Z headings, and two compact bottom settings actions without a separate heading. Holding the cog previews only Omagara settings and Omalauncher settings. Empty Search places the most recently opened app first.
- **Notifications:** Compact grouped cards with optional local notification timestamps, consistent magnetic swipe feedback, expandable actions/replies, bottom scroll clearance, and pull feedback.
- **Appearance:** Connected, content-fitted shade for the clock, date, and event, with theme-aware alphabet, notification, and app-label shades. Optional shading and independent corner rounding.
- **Controls:** System/12-hour/24-hour clock format (System default), theme/light/dark text colors, contrast, icon overlays, fonts, and Reduce Motion.
- **Utilities:** Calendar, next alarm, timer, stopwatch, and world clocks.

Slide onto the cog below the last alphabet letter (with haptic feedback) to navigate to the bottom settings menu. Select Omagara settings or Omalauncher settings there. Long-press Search still opens Omagara settings directly.

Time format defaults to **System**. Omalauncher currently does not expose Android's 12/24-hour setting, so System uses 24-hour time as a fallback. The format will automatically match Android when Omalauncher adds the `android.system.time24h` value. Manual 12-hour and 24-hour overrides work now.

## Limitation

OWL animations are capped at 60 FPS, including on 90/120 Hz displays. Higher frame rates require an Omalauncher engine change.
