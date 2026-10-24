# IMD radar

Live radar frames from the India Meteorological Department's own public product
URLs for all 47 stations, plus model wind, on one home-screen tile.

## What it shows

- **live** — the station's current PPI (dBZ) frame, with the time IMD stamped it
  on. IMD refreshes these every few minutes.
- **diff** — the two most recent frames side by side, the shared area cropped
  around the antenna and enlarged, so you can see which way the cells moved.
- **prev** — the frame before the current one.
- **wind** — Open-Meteo's model wind at 10, 80 and 120 m for the station, and a
  second block for the locked spot when one is locked.
- A search over the 47 stations, the last three picks kept as buttons, and a
  refresh interval of 10, 20 or 30 minutes.
- Two named spots locked by latitude and longitude. They show as a beating mark
  on the picture, at the true distance from the antenna, and the caption gives
  the bearing and range. Drag to pan, tap to zoom to 5x, tap again to reset.

## Where the data comes from

- Radar: `https://mausam.imd.gov.in/Radar/<product>_<station>.gif`, the same
  frames IMD's own radar page shows. Fetched with a plain GET and an
  identifying User-Agent; frames are cached under
  `~/.cache/omalauncher-imd-radar` and the previous one is kept for the diff.
- Wind: `https://api.open-meteo.com/v1/forecast`, a public API that needs no key
  and asks only for attribution (CC-BY-4.0), which the wind tab shows. It is a
  blended weather model (DWD ICON and NOAA GFS) on a grid of some ten
  kilometres, so it is an analysis rather than a measurement, and two points a
  few kilometres apart usually read the same. IMD's own Doppler VVP product is
  not read: its plot layout differs from station to station, so a reader that
  works for one invents numbers for the rest.
- Nothing else is contacted, and no account or token is involved.

## Privacy

The station codes and coordinates are IMD's published ones. If you lock a spot,
its latitude and longitude are sent to open-meteo.com as part of the wind
request, and stay in the widget's own state on the phone otherwise. The widget
never reads a device location permission.

## Range

A frame's pixel-to-kilometre scale comes from the plot radius, which is read off
the header of the stations marked verified (Chennai, Visakhapatnam, Karaikal and
Mumbai-Colaba at 150 km, Pallikaranai at 85 km). Where none was verified the
widget assumes 150 km, the radius IMD's PPI products plot at today, and the lock
caption says so.

## Needs

`curl`, `jq`, `gawk` and `imagemagick` on the Arch side of the launcher; owl 8
for `enc()`, which builds the wind URL from the selected station.
