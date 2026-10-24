# CAVA Android Visualizer

Install and start the **WiFi Audio Streaming** app on Android. Choose Send
(Server), enable Internal Audio and grant capture permission, select HTTP/Web,
and start streaming. Play audio on the phone. The widget contains its own small
bridge; it does not need separate helper files. In the settings screen, enter
the app's IP address and port (for example, `192.168.1.20:8080`) or its HTTP
URL. It saves when you leave settings with Back or Close. If there is no audio,
make sure Internal Audio is toggled on in the app settings. If latency is too
high, decrease it in the app.

The widget uses the declared Arch packages `python`, `cava`, and `ffmpeg` to
connect to `http://<IP>:<port>/stream`, decode audio and draw live spectrum bars.
The launcher offers to install any missing packages.

## Appearance and playback

The current track's album art can fill the tile and fade from left to right into
the theme background. Album art visibility and background blend are adjustable;
**Default** restores 90% art visibility and 120% background blend. These choices
persist across restarts. When no artwork is available, the theme background is
shown. Album art and media controls use Android media sessions and require
notification access; settings offers a permission shortcut when needed.

Enable **music player controls** to show previous, play/pause and next at the
bottom right. Their backgrounds are translucent. The top-right pause button
pauses the visualizer independently of music playback and stops its audio
pipeline until resumed.

## Spectrum settings

- **Frequency layout:** mono shows low to high frequencies from left to right;
  stereo mirrors the two channels with bass at the center. Both use 50 Hz–10 kHz.
  Stereo rounds odd bar counts up to the next even number.
- **Sensitivity:** 1–100. **Auto sensitivity** gradually reduces display gain
  when peaks repeatedly hit the top, ignores isolated peaks and recovers slowly
  during quieter music. It leaves the saved manual sensitivity unchanged and
  does not increase gain during silence.
- **Jitteriness:** higher values make the response faster and noisier.
- **Wave smoothing:** Off, Bass only, or Full spectrum. Bass only blends CAVA-style
  wave shaping into the lowest third of each channel while preserving upper
  bands. Full spectrum uses CAVA's native wave filter. Both use a narrower wave
  spread to keep peaks distinct.

**Reset CAVA defaults** restores 61 bars, sensitivity 77, jitteriness 32, mono,
auto sensitivity enabled and full-spectrum smoothing. Existing saved settings
are retained until changed or reset.

The bridge runs at 20 FPS, sends decoded PCM directly from FFmpeg to CAVA through
a FIFO, skips duplicate output, checks settings once per second and backs off
failed connections up to 30 seconds. Battery savings have not been measured.
