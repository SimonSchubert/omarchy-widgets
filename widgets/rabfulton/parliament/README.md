# Parliament audio

Listen to official House of Commons and House of Lords audio in the background.
Tap the tile to choose a house and a sitting. The round play button becomes a
stop button while connecting or playing. The tile supports one-row layouts
(minimum 3×1), wider tiles, and narrow, taller tiles.

The sitting list distinguishes live, scheduled and recorded events. Replays
include elapsed/total time, a seek slider, and −30/+30 second buttons. Seeking
reconnects at the requested position, so allow a short buffering pause. Volume
uses Android's media volume. The website button opens Parliamentlive.tv.

## Dependencies and implementation

Requires Arch Linux with `python`, `ffmpeg` and `pulseaudio`. No systemd service,
cron job, Docker container, kernel module or privileged helper is used.

The OWL file includes the entire readable Python backend. A small bundled
bootstrap atomically writes that source to `~/.cache/owl-parliament/player.py`
and runs it with Python. It never downloads executable code, decodes a hidden
payload, or evaluates server-provided commands. Dynamic values use OWL's
`sh()`; Python launches subprocesses with argument lists, without a shell.

The backend reads sitting listings from `parliamentlive.tv`, resolves the
official player at `videoplayback.parliamentlive.tv`, and requests an anonymous
playback session from `exposure.api.redbee.live`. No user account or API key is
required. The session token stays in the player process's memory. Audio-only
HLS comes from Parliament's Red Bee CDN. FFmpeg decodes audio into `pacat` for
PulseAudio; video is neither downloaded nor decoded.

Cache files, playback metadata, process identity, progress and a diagnostic log
are kept only under `~/.cache/owl-parliament/`. Stop targets only the process
group recorded by this widget, after checking its Linux process start time.
Playback is started only by a tap and continues while the widget screen is
closed. Listings refresh every five minutes and status every five seconds
while the launcher keeps the widget's sources active.

## Limitations and validation

This is an unofficial client for Parliament's public website, whose page/player
structure may change. It shows the recent sittings listed by that site, rather
than a complete searchable archive. Live playback can only be checked while a
house is sitting; recorded Commons and Lords decoding, background output,
stopping, absolute seeking and 30-second backward seeking were checked on
Arch Linux ARM under Omalauncher/proot. The packaged backend was also checked
through the launcher's live sources.

Licensed under MIT. The widget's license does not change Parliament's rights
or terms for its recordings. See [Parliament Live help](https://www.parliament.uk/business/parliament-tv/parliament-live-help/).
