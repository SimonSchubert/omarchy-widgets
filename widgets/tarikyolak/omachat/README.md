# OmaChat

**Old-school IRC vibes. Matrix-style terminal. Live chat, right on your home screen.**

OmaChat is a free, text-only community chat widget for OmaLauncher, inspired by classic mIRC and terminal chatrooms.

Join the public **#general** channel, choose a nickname and chat with other OmaChat users in real time. No registration, email address or account required.

OmaChat connects to a shared Cloudflare-hosted chat service, also accessible through the [OmaChat web client](https://chat.omachat.workers.dev/).

## Features

- **Native OmaLauncher widget** with a compact 3×2 home-screen layout.
- **Matrix-inspired appearance** with a black background, green terminal text and cyan timestamps.
- **Live public chat** shared between the widget and browser.
- **Recent messages** displayed directly on your home screen.
- **Full-screen chat** with a participant list and online user count.
- **Custom nicknames** that can be changed without registering.
- **IRC-style commands** for nicknames, actions and chat utilities.
- **Text-only messaging with no clickable hyperlinks**, link previews or attachments.
- **Long-press message copying**, including URLs and emojis.
- **Automatic profanity filtering and anti-spam protection**, including temporary mutes for repeated violations.
- **Connection recovery** after unexpected network interruptions.
- **Message delivery feedback** showing when the server accepts a message.

## Getting started

Open OmaChat and press **CONNECT** to join `#general`.

The server initially assigns a guest nickname. You can select your own using **[change]** and **[set]**. Your preferred nickname is saved locally and requested when you reconnect, subject to availability.

Nicknames are not registered or permanently reserved.

Press **DISCONNECT** when you want to leave the chatroom.

## Chat commands

| Command | Description |
|---|---|
| `/nick name` | Change your nickname |
| `/me action` | Send an IRC-style action |
| `/users` | Request information about online users |
| `/help` | Display available commands |
| `/clear` | Clear your local chat view |

The **[ USERS ]** control also opens the participant list.

**Note:** `/clear` only hides messages on your device. It does not delete messages from the server or other users' devices.

## Automatic moderation

OmaChat includes server-side automatic moderation to help keep the public chatroom welcoming and reduce abuse.

- **Profanity filtering:** Recognised swear words, offensive expressions and discriminatory slurs are automatically masked with `****`.
- **Anti-spam protection:** Excessive message flooding and repeated identical messages can trigger restrictions.
- **Temporary mutes:** Users who repeatedly send prohibited language or spam may be temporarily prevented from sending messages.
- **Automatic recovery:** Sending becomes available again after a temporary mute expires.

Moderation happens on the server, so the same rules apply to both the OmaLauncher widget and the browser client.

The filtering system uses predefined rules. It may occasionally miss inappropriate content or flag harmless text.

## Connection and message history

OmaChat starts offline. You choose when to connect.

If the initial connection cannot complete within approximately 15 seconds, OmaChat stops the attempt and lets you retry. After a successful connection, it can automatically reconnect following temporary network interruptions.

The chat displays up to 100 recent server events from its 24-hour history window. This is not a guarantee that messages have been deleted elsewhere.

**Messages are strictly text-only.** URLs may be written in messages, but they remain plain text and cannot be clicked or tapped to open websites.

Users can **long-press an individual message to copy its text** to the Android clipboard, including URLs, punctuation and emojis. Copied URLs can then be pasted into a browser.

OmaChat does not support active hyperlinks, link previews, file uploads, images or private messaging.

A **Message sent.** confirmation means the server accepted your message, not that another participant read it. Messages with uncertain delivery are not automatically resent.

## Privacy and community safety

**OmaChat is a public chatroom.** Messages and nicknames may be visible to other participants.

- Do not share passwords, personal information or sensitive data.
- Messages are not end-to-end encrypted.
- Other participants may copy or retain messages.
- Automatic moderation helps reduce abuse but cannot guarantee that every harmful message will be prevented.

No account is required, but using a guest nickname does not guarantee anonymity from the service operator or network infrastructure.

## Requirements

- OmaLauncher 0.16.0 or newer, with OWL 17 support.
- An internet connection.
- Access to the public OmaChat service.

The widget depends on `wss://chat.omachat.workers.dev/ws`. Service interruptions may temporarily prevent chatting. Continuous background connectivity is not guaranteed.

OmaChat is a community chat widget, not a private messaging or encrypted communications service.
