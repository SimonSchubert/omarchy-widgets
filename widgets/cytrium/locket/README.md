# Unofficial Locket Widget for OmaLauncher

An **unofficial** [OmaLauncher](https://github.com/SimonSchubert/omarchy-widgets) home-screen widget and full-screen feed view for **Locket**, written in OWL.

> **Disclaimer:** This is an independent, unofficial client for Locket and is not affiliated with, endorsed by, or provided by Locket Labs, Inc.

## Features

- **Live Home-Screen Tile**: Displays the latest photo moment from your friends with sender avatar, relative timestamp, quick moment cycling (`1/N ›`), and Locket-style frosted caption pill.
- **Instant Notification Sync + Gentle Background Polling**: Detects incoming notification timestamps from the Locket Android app (`com.locket.Locket`) to sync new moments right away, while polling in the background only every 20 minutes to save battery and minimize API requests.
- **Multi-Friend Feed**: Lazy-loaded full-screen feed (`owl: 11`, `lazy: true`, capped to 12 moments) that fetches friend profiles via `fetchUserV2`.
- **Emoji Reactions & Direct Chat Replies**: React with `💛 ❤️ 🔥 😍 😂 💕` (`reactToMoment`) or send text replies directly to Locket chat (`sendChatMessageV2`).
- **Flexible Sign-In**: Supports signing in on-device via Email & Password, Phone & Password, or Firebase `refreshToken`, with automatic token renewal and per-install generated device ID.
- **Privacy First**: No credentials, tokens, emails, or user IDs are hardcoded in the widget source. Signing out clears all cached moments and friend profiles.

## Installation

- **From the OmaLauncher Widget Store**: Long-press empty space on the home screen, open the **Store**, find **locket** under **media**, and tap **Install**.
- **Manual Installation**: Copy [`widget.owl`](./widget.owl) into `~/.config/omalauncher/widgets/locket.owl`.

Tap the **Locket** tile on your home screen to open the full-screen view and sign in under the **sign in / account** tab.

## License

MIT
