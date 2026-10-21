# daysUntil

Counts the days to the dates you care about, nearest first. The tile hides past
dates and anything past the current year plus January; each row has a muted
track whose colored fill drains as the date comes nearer.

Tap the tile to manage dates. The dates list scrolls under the fixed tabs; tap
a row (or its ✎) to edit it. Adding and editing share one form: a month calendar
or manual `YYYY-MM-DD`, an emoji label, a yearly checkbox, and add/save or
cancel. Saving is optimistic: the row and tile update at once, and a `saving…`
note stays until the JSON file has caught up.

- Dates are stored in `~/.local/share/omalauncher/daysUntil.json`; a missing
  file shows the built-in Halloween/Christmas/New Year defaults.
- `preview.png` is the tile with those defaults.
