# Herdr control

Monitor named Herdr sessions on a remote machine and open a selected session in a terminal.

## Setup

1. Install Herdr on the remote machine.
2. Ensure the remote account accepts SSH key authentication.
3. Open **settings** and enter an OpenSSH target such as `user@server.example.com` or an SSH config alias.
4. Tap a session to open it.

The widget runs `ssh` and `jq` locally. The remote host must provide `~/.local/bin/herdr session list --json`.
