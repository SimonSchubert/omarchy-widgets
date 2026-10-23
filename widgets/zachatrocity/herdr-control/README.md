# Herdr control

Monitor named agents in remote Herdr sessions and open an agent directly in a terminal.

## Setup

1. Install Herdr on the remote machine.
2. Ensure the remote account accepts SSH key authentication.
3. Open **settings** and enter an OpenSSH target such as `user@server.example.com` or an SSH config alias.
4. Tap an agent to attach directly to it.

The widget polls running session snapshots every 15 seconds. It runs `ssh` and `jq` locally; the remote host must provide `~/.local/bin/herdr session list --json` and the session snapshot API.
