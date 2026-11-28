# feed the agent

Feed it a note, an idea, a todo or a bug fix: one line at a time, from the
tile or by voice. It connects to your agent and your file system — the note is
written into a folder of your own, and your agent reads and writes those files
to organize, prioritize and remind you. No model runs on the phone.

The 6×1 tile is a text field with a `feed it` button, a mic, a priority tag and
— once a computer is set — a `sort` button. Tap it for the full screen.

## What it does

- **Capture**: type a thought, or tap the mic and say it. The phone's own
  recognizer does the words; nothing leaves the phone.
- **Write it down**: the line goes into your note, under the section line you
  chose, at the top or the bottom of that list, with a `{date}` or
  `{date:time}` prefix if you want one.
- **Priority**: the `now` tag bumps a note up your list, so the agent knows to
  read it first.
- **Sort**: with a computer set up, `sort` asks the agent to clear the inbox
  and run the rules you gave it. It sorts when you tap, or whenever your agent
  next checks in.
- **The screen**: the note list, the priority bump, what gets written (section
  line, prefix, top or bottom), two notification switches, and the setup card.

## Where the note goes

Two answers, and no permission needed for either default:

- **This phone**: `/sdcard/Documents/feed.md`, which the phone's file apps can
  see too.
- **A folder you granted to Omalauncher** — your Obsidian vault, say — with the
  file name you pick, such as `_inbox.md`. It can sit in a subfolder, and
  `{date}` in the name starts a new note each day.

## The agent

The agent is a small HTTP contract, not a model in the widget: `GET /status`
says whether it is there, `POST /drain` asks it to sort. It can live on a
desktop or a server of your own on the LAN or Tailscale, at an `https://` cloud
address, or on this phone, where it is a small local server that calls
`~/.config/feed-agent/sorter`.

**Set the agent up to read and write your folder and named files, and keep them
correctly synced — without that, the widget captures and the agent does
nothing.** The widget never talks to a model and never uploads a note.

## Privacy

The only network calls are to the address you set, and to nothing else. There
is no token: a secret can only be sent to a fixed `https://` host, and these
are your own machines, so keep the LAN and Tailscale addresses off the open
internet. Dictation runs through Android's own speech recogniser.

## Requires

`python`, `gawk` and `coreutils` (the folder picker and the phone-path lookup
are small Python programs), and an agent that answers the two routes above.

## Notes

- The tile is a text field, so it opens the screen from a gear button rather
  than a whole-tile tap.
- `meta`: version 2.7, MIT, category `productivity`, owl 19.
