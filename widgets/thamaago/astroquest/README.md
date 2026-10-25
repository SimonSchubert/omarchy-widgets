# AstroQuest

A home-screen stargazing widget with a full-screen sky explorer, 15 observing quests, a discovery logbook, an astronomy quiz, Cosmic and red night modes, and a 12-hour time preview. Aim manually using the direction controls; it does not read phone orientation or GPS coordinates.

Requires OWL 13 and the Arch packages `python` and `python-astropy`. Astronomy uses Astropy's bundled solar-system ephemeris and Earth-rotation tables, with automatic data downloads disabled. Positions are intended for casual stargazing, not precision measurements.

No observing location is preset. Choose a city or enter coordinates in the widget. City searches and selected coordinates are sent to Open-Meteo for geocoding and cloud-cover forecasts. The chosen site and discovery progress persist locally on the phone.

Version 3.3. License: MIT.
