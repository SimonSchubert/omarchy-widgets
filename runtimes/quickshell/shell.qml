// A board of OWL widgets in a window, with nothing but Quickshell:
//
//   quickshell -p runtimes/quickshell
//
// It draws every widget.owl under OWL_WIDGETS (default: this repo's
// widgets/) on the launcher's 6-column grid, in the Omarchy theme when there
// is one, and saves what they persist under ~/.local/state/owl/. The runtime
// is the folder above; a shell that embeds it does what this file does.

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "." as Owl
import "Owl.js" as OwlJs

ShellRoot {
  id: shell

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string dir: {
    var d = Quickshell.env("OWL_WIDGETS")
    if (d) return d
    var u = String(Qt.resolvedUrl("../../widgets"))
    return u.indexOf("file://") === 0 ? decodeURIComponent(u.slice(7)) : u
  }

  // Omarchy's palette when the theme is there, Tokyo Night's otherwise.
  property var palette: OwlJs.themeFromToml("")
  FileView {
    path: shell.home + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: shell.palette = OwlJs.themeFromToml(text())
  }

  Owl.OwlHost {
    id: host
    monoFamily: "JetBrainsMono Nerd Font"
    iconFamily: "JetBrainsMono Nerd Font"
  }

  // Every widget.owl, one level of author folders down, as in the store.
  Process {
    id: find
    running: true
    command: ["bash", "-c", "find \"$1\" -name '*.owl' | sort", "find", shell.dir]
    stdout: StdioCollector {
      onStreamFinished: shell.files = text.split("\n").filter(function(l) { return l !== "" })
    }
  }
  property var files: []

  FloatingWindow {
    id: window
    implicitWidth: 480
    implicitHeight: 900
    color: OwlJs.hex8(shell.palette.background)
    title: "owl"

    readonly property real gap: 6
    readonly property real pitch: (width - 2 * 12 + gap) / 6
    // The launcher's cell is 69 dp; a widget is drawn at the scale that gives
    // it the same one here.
    readonly property real dp: pitch / 69

    // First fit at each widget's own size, in file order.
    readonly property var places: {
      var used = [], out = []
      for (var i = 0; i < tiles.count; i++) {
        var t = tiles.itemAt(i)
        var size = t && t.owl.program ? t.owl.size : [3, 2]
        var w = Math.min(size[0], 6), h = size[1]
        search: for (var y = 0; ; y++) for (var x = 0; x + w <= 6; x++) {
          var free = true
          for (var yy = y; yy < y + h && free; yy++) for (var xx = x; xx < x + w; xx++) if (used[yy] && used[yy][xx]) { free = false; break }
          if (!free) continue
          for (var a = y; a < y + h; a++) { used[a] = used[a] || []; for (var b = x; b < x + w; b++) used[a][b] = true }
          out.push({ x: x, y: y, w: w, h: h })
          break search
        }
      }
      return out
    }

    Flickable {
      anchors.fill: parent
      contentHeight: board.height + 24
      clip: true

      Item {
        id: board
        x: 12
        y: 12
        width: window.width - 24
        height: {
          var rows = 0
          for (var i = 0; i < window.places.length; i++) rows = Math.max(rows, window.places[i].y + window.places[i].h)
          return rows * window.pitch
        }

        Repeater {
          id: tiles
          model: shell.files
          delegate: Rectangle {
            id: tile
            required property string modelData
            required property int index
            readonly property alias owl: widget
            readonly property var place: window.places[tile.index] || { x: 0, y: 0, w: 3, h: 2 }
            x: tile.place.x * window.pitch
            y: tile.place.y * window.pitch
            width: tile.place.w * window.pitch - window.gap
            height: tile.place.h * window.pitch - window.gap
            color: widget.alpha(widget.ink("background"), 0.88)
            clip: true

            Owl.OwlWidget {
              id: widget
              anchors.fill: parent
              anchors.margins: (widget.program ? widget.program.padding : 12) * widget.dp
              path: tile.modelData
              host: host
              palette: shell.palette
              active: window.visible
              cols: tile.place.w
              rows: tile.place.h
              dp: window.dp
              screenWidth: window.width
              screenHeight: window.height
            }

            TapHandler {
              enabled: !!(widget.tree && widget.tree.onTap)
              onTapped: (p) => widget.tree.onTap(p.position.x / widget.dp, p.position.y / widget.dp)
            }

            Owl.OwlNode {
              anchors.fill: widget
              visible: !widget.error && !!widget.tree
              widget: widget
              node: !widget.tree ? null : widget.tree.children.length === 1 ? widget.tree.children[0]
                : { kind: "Column", p: { gap: 0 }, h: {}, a: {}, c: widget.tree.children }
            }

            Text {
              anchors.fill: widget
              visible: !!widget.error
              text: widget.error
              color: widget.ink("red")
              font.family: "monospace"
              font.pixelSize: 10
              wrapMode: Text.Wrap
            }

            // The launcher's frame: square, 2 dp, the theme's muted color.
            Rectangle {
              anchors.fill: parent
              color: "transparent"
              border.width: 2 * widget.dp
              border.color: widget.ink("muted")
            }
          }
        }
      }
    }
  }
}
