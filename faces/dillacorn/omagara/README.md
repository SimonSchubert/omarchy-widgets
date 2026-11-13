# Omagara

Niagara-inspired OWL 21 home face for [Omalauncher](https://github.com/SimonSchubert/omalauncher). No extra packages or shell commands.

## Features

- **Alphabet:** Elastic A–Z navigation with a continuous, bending shade. Move the rail left or right, optionally use opposite-edge input, and configure haptics.
- **Apps:** Buffered full-height browser with elastic ends, adjustable scale, and shaded labels. Empty Search places the most recently opened app first.
- **Notifications:** Compact grouped cards, magnetic swipe dismissal, expandable actions/replies, bottom scroll clearance and pull feedback.
- **Appearance:** Theme-aware shades for the clock, date, event, alphabet, notification headings, and app names. All are optional; shading defaults on. Corner rounding is independent for each element and defaults off.
- **Controls:** Theme/Light/Dark text colors, contrast, icon overlays, fonts, and Reduce Motion.
- **Utilities:** Calendar, next alarm, timer, stopwatch, and world clocks.

Long-press Search to open Omagara Settings.

## Limitations

- Contact search: OWL 21 exposes no Android contacts source or permission action.
- Home/Back or focus-loss dismissal of alphabet browsing: no face-level event is exposed.
- Haptic strength: controlled by Android; Omagara can adjust feedback frequency only.
- Automatic wallpaper brightness sampling and a true bottom alpha-mask fade: unavailable.
- Full-list notification overscroll: native lazy lists expose no scroll offset/controller; v1.4 uses header/footer pull feedback.
- High-refresh animation: OWL is capped at 60 FPS, including on 90/120 Hz displays, and slow widgets may run slower. Higher FPS requires an Omalauncher engine change.
- Automatic home-face sound effects for gesture/animation events: restricted; the abandoned coin/game experiments are not part of v1.4.
