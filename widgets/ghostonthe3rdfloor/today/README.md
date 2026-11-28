# Today — weather and date

A home-screen widget showing the date and weather where you are: a city you type, else the phone's location once you allow it, else by IP. Tap it for 24 hours, three days, wind, UV, sun and moon, °C or °F, and the weather source to switch.

## Source

Based on `today` by SimonSchubert (@simonschubert) in the Omarchy widget store, version 1.16 — a wttr-only build. This edition keeps the original's look and translations, and adds:

- Power saving: the clock ticks every 2 hours instead of every minute, with the date held right at midnight.
- More weather sources: wttr, open-meteo and openweathermap, with a persisted source picker and an openweathermap API key input (kept as a secret).
- Units (°C/°F) and per-provider links (yr.no, open-meteo, openweathermap) on the full-screen view.

No shell commands, so no `requires` packages.
