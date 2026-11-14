# Omagara v1.6

Niagara-inspired OWL 21 home face for [Omalauncher](https://github.com/SimonSchubert/omalauncher). No extra packages or shell commands.

## Features

- **Alphabet:** Elastic A–Z navigation with app previews biased toward frequently launched apps (less aggressively near A), a letter-sized Settings cog in the shaded worm tail, distance/speed-sensitive wiggle, optional opposite-edge input, and configurable haptics.
- **Apps:** Buffered full-height browser with elastic ends, adjustable scale, padded A–Z headings, and two compact bottom settings actions without a separate heading. Holding the cog previews only Omagara settings and Omalauncher settings. Empty Search places the most recently opened app first.
- **Notifications:** Compact grouped cards with consistently aligned optional timestamps, magnetic swipe feedback, expandable actions/replies, native list scrolling, bottom clearance, and matching rubber-band rebound when pulling the top header or bottom footer.
- **Appearance:** Connected, content-fitted shade for the clock, date, and event, with theme-aware alphabet, notification, and app-label shades. Optional shading and independent corner rounding.
- **Controls:** Settings organized into Clock, Apps, Alphabet, Notifications, Style, and More. Manual 12-hour/24-hour time format (24-hour default), text colors, contrast, icons, fonts, and Reduce Motion.
- **Utilities:** Calendar, next alarm, timer, stopwatch, and world clocks.

Slide onto the cog below the last alphabet letter (with haptic feedback) to navigate to the bottom settings menu. Select Omagara settings or Omalauncher settings there. Long-press Search still opens Omagara settings directly.

Time format is selected under **Clock** in Omagara settings. Omalauncher OWL does not expose Android's system time format. Longer lists (corner rounding, world clocks, backup/reset) are collapsed until opened.

## Limitation

OWL animations are capped at 60 FPS, including on 90/120 Hz displays. Higher frame rates require an Omalauncher engine change.
