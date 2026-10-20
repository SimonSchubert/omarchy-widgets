# NWS radar

The nearest National Weather Service radar loop, on a home-screen tile. It asks wttr.in where the phone is, or uses a city typed on the full screen, then loads that site's reflectivity frames from radar.weather.gov.

Radar imagery is produced by NOAA's National Weather Service and is in the public domain. The frames are downloaded when the tile runs. They are not stored in this repository.

Needs `curl` and `jq`.
