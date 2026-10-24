# Photo Widget

A responsive and dynamic home-screen photo widget for Omalauncher.

![Photo Widget Preview](preview.png)

## Features

- **Dynamic Box Layout**: Edge-to-edge photo display that fills any grid dimensions (2x2, 3x3, 4x3, 3x6, etc.) without letterbox borders. Supports both Cover and Contain fit modes.
- **Album Slideshow with Smooth Fade**: Supports multiple photos (up to 10 photos in album) with smooth crossfade animation and configurable transition intervals (5s, 8s, 15s, 30s, 60s). Reverts to single-photo mode seamlessly.
- **Dynamic Theme Adaptation**: Intelligently adapts text, buttons, backgrounds, and borders to any active Omarchy theme (both light and dark modes).
- **Embedded Offline Default**: Includes an embedded base64 default photo, working instantly out of the box without requiring initial setup or internet connection.
- **Multi-Source Support**:
  - Direct web image URLs (HTTP / HTTPS).
  - Cloud share links with automatic direct-link resolution (Google Drive, Dropbox, Imgur).
  - Android device storage (`/storage/...`, `~/Pictures`).
- **Interactive Configuration**: Tap the widget to open a full-screen sheet with real-time download status, high-resolution preview, and quick access to device pictures.

## Requirements

Declared in `requires`:
- `python`
- `python-pillow`
- `curl`

## Author

Created by [zyanmd](https://github.com/zyanmd). Distributed under the MIT license.
