# NWS radar

The nearest National Weather Service radar loop, on a home-screen tile. Unless you type a city on the full screen, it locates the phone by its IP address through wttr.in (so your IP goes to wttr.in, every 30 minutes). It then asks api.weather.gov for the nearest radar site, once per place, and loads that site's reflectivity frames from radar.weather.gov.

The radar is checked every 15 minutes, about as often as the NWS loop changes. Each frame is asked for only if it is newer than the copy on the phone, so a check that finds nothing new downloads no images.

Radar imagery is produced by NOAA's National Weather Service and is in the public domain. The frames are downloaded when the tile runs and kept in `~/.cache/omalauncher/nws-radar`. They are not stored in this repository.

Needs `curl` and `jq`.
