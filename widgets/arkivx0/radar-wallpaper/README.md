# Radar wallpaper

Live National Weather Service radar as the home-screen wallpaper. The tile downloads the public CONUS-LARGE loop from radar.weather.gov, draws it on a night map, and centers it on this phone. Each national frame shows the time from the corner the phone crop cuts off, and a dot for that frame's place in the loop.

Radar imagery is produced by NOAA's National Weather Service and is in the public domain. The frames are not stored in this repository. Each phone downloads them when the tile runs.

Needs `curl` and `ffmpeg`.

## What it does on the phone

- **Location:** the tile asks wttr.in where the phone is from its IP address, so your IP goes to wttr.in about every 30 minutes. The latitude and longitude, rounded to 2 decimals, are saved in `~/.config/omalauncher/nws-wallpaper.conf`. When wttr.in can't place the IP, the tile says so and keeps the last place it had.
- **Background program:** the tile writes a bash program to `~/.local/share/omalauncher/nws-wallpaper/nws-wallpaper` and starts it as a background daemon. The daemon runs `curl`, `ffmpeg`, `ffprobe`, `ps`, `kill` (only its own older copies) and standard shell tools. Once a minute the tile touches a heartbeat file. When that is more than 3 minutes old, or the wallpaper is switched off, the daemon puts your previous wallpaper back and exits.
- **Files:** the wallpaper frames (`nws-conus-*.jpg`) are written to `~/.config/omarchy/backgrounds/<theme>/`, so they also show in Style's picker while the wallpaper is on. They are removed when you switch it off or pick another background. Its working files are in `~/.cache/omalauncher/nws-wallpaper/`.
- **Data:** the national loop is about 4 MB, and it is downloaded every 15 minutes while this tile's page is on screen (up to 16 MB an hour). That is by design: the national mosaic is the sharp one, and the regional loops are too blurry for a full-screen wallpaper. Updates can be switched off on the full screen, and then the frames already saved keep playing.
- **Battery:** frames step no faster than every 2 seconds (4 on slow), and each new loop or settings change re-renders the frames once with ffmpeg at low priority. A settings change is applied after it has been still for 3 seconds.
