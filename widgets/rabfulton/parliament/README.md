# Parliament audio

Listen to official UK Parliament audio: the Commons, Lords, committees,
Westminster Hall and other proceedings listed on Parliamentlive.tv.

Open the widget to browse **All**, **Commons**, **Lords** or **Committees** and
filter sessions by title or date. The timeline opens near the live sessions:
recent recordings above, upcoming sessions below. **Earlier recordings** expands
history upward and fetches further pages of the official archive when needed.
Live sessions have a subtle highlight.

The compact player has play/pause, stop, a replay timeline and ±30-second media
buttons. Tapping play immediately shows a connecting indicator. The button
switches to pause when audio actually starts, independently of cache filling.
Use Android's system controls for volume. The external-link icons open the
website or the current session. Tiles can shrink to 3×1 and work at larger sizes.

## Playback and dependencies

Requires Arch Linux with `python`, `mpv` and `pulseaudio`. This replaces the old
FFmpeg-to-pacat pipeline with mpv's audio player and local JSON IPC controls.
No systemd service, cron job, Docker container or privileged helper is used.

Pause keeps the player and its network/audio buffers intact; resume uses the
same process. Seeking also uses that player and works while paused. A seek
outside the buffered range can need network data. Playback continues while the
widget screen is closed; stop releases the player process group. The network
cache reads ahead for up to 60 seconds within a 32 MiB forward/8 MiB backward
memory budget. Video is neither downloaded nor decoded: the official playback
request asks for audio-only HLS and mpv has video disabled.

## Bundled backend and network access

The OWL file includes the entire readable Python backend. A small bundled
bootstrap atomically writes that source to `~/.cache/owl-parliament/player.py`
and runs it locally. It never downloads executable code or evaluates server
content as commands. Dynamic shell arguments use OWL's `sh()`; subprocesses
inside Python use argument lists, without a shell.

The backend reads listings/archive pages from `parliamentlive.tv`, resolves
player configuration at `videoplayback.parliamentlive.tv`, and requests an
anonymous playback session from `exposure.api.redbee.live`. No user account or
API key is needed. The session token stays in process memory. Audio comes from
Parliament's Red Bee CDN. Recently resolved recording URLs are cached for ten
minutes. Known recordings skip an extra player-state lookup; duration comes
from the player rather than a duplicate manifest fetch, and authentication
runs in parallel with configuration lookup.

To avoid slow parallel A/AAAA DNS replies observed under Android/proot, the
helper adds `single-request-reopen` to its own `RES_OPTIONS`. The player child
inherits that setting. System DNS configuration and nameservers are unchanged.

All cache files, player metadata, local IPC sockets, process identities and the
player log live under `~/.cache/owl-parliament/`. Stop checks the recorded Linux
process start time before signaling its group. The player reports buffering,
audio-start and position events directly; Python is not repeatedly spawned to
poll new playback. A five-second status tick supports an already-running
player from an older version until the next stream starts. Listings refresh
every five minutes while the launcher keeps their source active.

## Validation and limitations

This is an unofficial client of Parliament's public website, whose page/player
structure may change. It initially combines the public listing pages and the
first archive page; earlier pages can be loaded rather than downloading the
whole archive. House metadata is available for the landing-page entries;
archive-only committee entries can appear under All/Committees until their
house is known. Session dates/titles are supplied by Parliament in English.

Checked with `owl-check` and the store's OWL review tool. Muted playback tests on
Arch Linux ARM under Omalauncher/proot covered Commons and Lords recordings,
duration discovery, first-audio timing, retained-buffer pause/resume, seeking
while paused, stopping and event-driven progress updates. A simulated IPC event
sequence checks that actual audio start ends the initial loading indicator even
when cache notifications arrive later. Listing/archive pagination and the
live-centred timeline were checked with current data and rendered previews.
The owner tested the local UI/playback changes before this submission.

Licensed under MIT. This license does not change Parliament's rights or terms
for its recordings. See [Parliament Live help](https://www.parliament.uk/business/parliament-tv/parliament-live-help/).
