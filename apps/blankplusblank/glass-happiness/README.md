# Glass Happiness

A falling-sand terrarium. Pour gravel, charcoal, perlite and soil, rake it level, water and mist it, put the lid on or take it off, and grow eight humidity-loving plants. A window shows a day and night: fast days of 8 minutes, or real time in a city you pick, with that city's sunrise, sunset and weather from Open-Meteo.

**For reviewers:** the simulation is a Perl script, kept inside `app.owl` as the `sim` string so this review covers it. The stream runs a small feed script (`feed`) with the sim's code as its argument, and the feed shares the tank with the home widget [glass-happiness-tank](../../../widgets/blankplusblank/glass-happiness-tank). Neither script downloads or runs anything else.

Files it uses:
- `~/.local/share/mossglass/tank.txt`: the saved tank
- `~/.local/share/mossglass/place.json`: the city you pick
- `~/.cache/mossglass/`: the latest frame, the background, and taps passed to the sim
