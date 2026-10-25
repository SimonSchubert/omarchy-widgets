# AstroQuest

A home-screen stargazing widget with a full-screen sky explorer, 15 observing quests, a discovery logbook, an astronomy quiz, Cosmic and red night modes, and a 12-hour time preview. It does not read phone orientation or GPS coordinates.

Requires OWL 13 and the Arch packages `python` and `python-astropy`. Astronomy runs locally using Astropy's bundled ephemeris and Earth-rotation tables, with automatic downloads disabled. Positions and brightness estimates are for casual stargazing; planet magnitudes are approximate and omit Saturn's ring brightness.

No observing location is preset. Choose a city or enter coordinates in the widget. City searches are sent to Open-Meteo; selected coordinates are sent for cloud-cover forecasts only when weather is enabled. The chosen site and discovery progress persist locally on the phone.

Version 3.6. License: MIT.
