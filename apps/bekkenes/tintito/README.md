# TinTito

A direct telnet/TLS MUD terminal for Omalauncher, with presets for Aardwolf,
Alter Aeon and Discworld, or any host you enter. It starts a small Python
client in the launcher's embedded terminal and speaks telnet NAWS/TTYPE/
CHARSET, so 256-colour ANSI art and box drawing line up.

- Packages: `python`.
- Controls: tap the terminal to type; `Ctrl-]` disconnects; the title-bar back
  chevron returns to the setup screen.
- TLS uses the system CA store (self-signed certificates are rejected).
- No account, bridge, or TinTito server: the terminal connects directly to the
  MUD you choose.

This is the launcher-edition terminal client. The browser client — a full
ANSI terminal with JetBrains Mono / IBM Plex Mono, scrollback and truecolor —
stays at <https://github.com/Bekkenes/tintito>.
