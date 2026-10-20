# Radar wallpaper

Live National Weather Service radar as the home-screen wallpaper. The tile downloads the public CONUS loop from radar.weather.gov, draws it on a night map, and centers it on this phone. Each national frame shows the time from the corner the phone crop cuts off, and a dot for that frame's place in the loop.

Radar imagery is produced by NOAA's National Weather Service and is in the public domain. The frames are not stored in this repository. Each phone downloads them when the tile runs.

Needs `curl` and `ffmpeg`.

The loop runs only while this tile's page is on screen. It fetches a new image every 15 minutes, steps no faster than every 2 seconds, and puts the previous wallpaper back when it is switched off or the home screen is gone.
