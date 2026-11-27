# OWL for SwiftUI

A third runtime for OWL, the widget language of this store: the same
`widget.owl` and `face.owl` files the Android launcher draws, drawn by SwiftUI
on macOS (and, as a library, iOS).

```sh
swift run OwlBoard                                  # every face and widget in this repo
OWL_WIDGETS=~/my-widgets swift run OwlBoard         # a folder of your own
OWL_THEME=path/to/colors.toml swift run OwlBoard    # an Omarchy theme; ~/.local/state/omarchy's by default
swift run owl-render widget.owl out.png --size 3x2  # one tile to a PNG, without a window
```

## How it works

The language isn't ported a third time: `Owl.js`, the Quickshell runtime's
port of the reference implementation, runs in JavaScriptCore, which every
Mac and iPhone has. Swift draws what it renders.

| File | Does |
| --- | --- |
| `Resources/Owl.js` | a copy of `../quickshell/Owl.js`, byte for byte: the language |
| `OwlScript.swift` | Owl.js in a `JSContext`, with time zones read from `/usr/share/zoneinfo` |
| `OwlBridge.swift` | one widget's Instance: a render crosses to Swift as one JSON text, and handlers and Canvas drawings stay in JavaScript as numbers |
| `OwlWidget.swift` | one widget file, live: compiles it, runs its sources, keeps its state, runs its actions, writes `.errors/<file>.txt`, reloads on save |
| `OwlHost.swift` | what a widget needs from the app around it, with defaults for a Mac |
| `OwlFacts.swift` | android.device, system, battery, volume, modes and network, read from the Mac |
| `OwlLayout.swift` | the launcher's layout rules: Compose's Row and Column measure order and weights, Box, Grid, Flow |
| `OwlNodeView.swift`, `OwlLeaves.swift` | the nodes |
| `OwlCanvasView.swift` | `Canvas` drawing calls, replayed onto a SwiftUI `GraphicsContext` each frame |
| `OwlTileView.swift` | a tile as the launcher frames one, and what `screen()` opens |

`OwlBoard` is the example app, as `shell.qml` is Quickshell's; `owl-render`
draws one tile offscreen; `owl-walk` runs `../quickshell/test/walk.js` in
JavaScriptCore.

## Embedding it

```swift
let host = OwlHost()                          // or a subclass: fonts, act(), media
let widget = OwlWidget(path: "/path/to/widget.owl", host: host, theme: .current())
widget.dp = cellSide / 69                      // the launcher's cell is 69 dp
widget.cols = 3; widget.rows = 2
widget.active = true                           // sources run and animations play while true

OwlTileView(widget: widget).frame(width: w, height: h)
```

Subclass `OwlHost` where the app differs: `monoFamilies`, `act(_:_:_:)` for
`terminal()`, `app()`, `launcher()` and the rest, `media` for android.media.

## How faithful it is

The language is held to `tools/owl.jar` by `../quickshell/test/run.sh`, which
on a Mac walks every store widget, face and edge case in JavaScriptCore as
well as node and must print the same bytes. `swift test` checks that the
bundled `Owl.js` is the Quickshell one, that every store file compiles, and the
layout rules. After changing `../quickshell/Owl.js`:

```sh
cp runtimes/quickshell/Owl.js runtimes/swiftui/Sources/OwlKit/Resources/Owl.js
```

Rendering was compared tile by tile with the launcher's own `previews/` with
`owl-render`. With JavaScriptCore's JIT off, as it is in an iOS app, an
animated Canvas like koi-pond takes about 2.5 ms a frame in Owl.js.

Where it differs, because Android is not here:

- **Commands** run in the Mac's own bash, from the home folder. Store widgets
  are written for Arch, so a command using GNU-only flags (`date -d`, …) fails
  unless Homebrew's `coreutils`, `gnu-sed`, `grep`, `findutils` or `gawk` are
  installed: their GNU names go first on the PATH when they are. iOS runs no
  commands, as the launcher runs none without Linux, and `linux` is false.
- **Shader** draws its `fallback`: AGSL is Android's.
- **Terminal** shows its command and opens it in Terminal.app when tapped.
- **Secrets** are kept in the Keychain, one item per widget file, bound to
  their servers as on the launcher.
- **Text** keeps a single line to the launcher's 1.17 em; wrapped text has the
  font's own line spacing, which SwiftUI can't make tighter.
- **frost** is a SwiftUI material: it blurs what's behind the node in the window.
- **Popup** is a popover.
- **android.*** answers what a Mac has: battery from IOKit, memory, storage,
  network bytes, volume through AppleScript, dark mode. Notifications, apps,
  recent, agents and the drawer are empty, there's no alarm, SIM or key bar,
  and android.media plays nothing.
- **media()**, **dnd()**, **settings()**, **androidApp()**, **notification()**,
  **open()**, **ask()**, **appAction()**, **workApps()**, **launcher()**,
  **pressKey()**, **typeText()** and **latch()** report that there's nothing to
  drive on a Mac; **torch()** and **haptic()** do nothing. An app that has them
  overrides `act()`.
- **Apps, panels and key bars** compile but have no place to open from here.
- `owl-render` draws a scrolling Column as a still one, and a text field as its
  text: `ImageRenderer` draws no AppKit views.
