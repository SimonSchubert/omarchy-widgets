// Draws one OWL widget offscreen to a PNG, as the board would show it:
//
//   owl-render <widget.owl> <out.png> [--theme colors.toml] [--size 3x2] [--dp 2] [--wait 3]
//
// Its sources run for --wait seconds first (commands, the web, the clock), so a tile shows what it has rather
// than "…". The tile is the launcher's: 69 dp cells, 6 dp gaps.
import AppKit
import OwlKit
import SwiftUI

var args = Array(CommandLine.arguments.dropFirst())
func option(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    let v = args[i + 1]
    args.removeSubrange(i...(i + 1))
    return v
}
let themePath = option("--theme")
let sizeText = option("--size")
let dp = Double(option("--dp") ?? "2") ?? 2
let wait = Double(option("--wait") ?? "3") ?? 3
guard args.count == 2 else {
    FileHandle.standardError.write("usage: owl-render <widget.owl> <out.png> [--theme colors.toml] [--size 3x2] [--dp 2] [--wait 3]\n".data(using: .utf8)!)
    exit(2)
}
let (src, out) = (args[0], args[1])

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let theme = themePath.flatMap { try? String(contentsOfFile: $0, encoding: .utf8) }.map { OwlTheme(toml: $0) } ?? OwlTheme(toml: "")
    let host = OwlHost()
    let w = OwlWidget(path: (src as NSString).standardizingPath, host: host, theme: theme)
    var cells = w.isFace ? (6, 12) : w.size
    if let s = sizeText?.split(separator: "x"), s.count == 2, let c = Int(s[0]), let r = Int(s[1]) { cells = (c, r) }
    let pitch = 69 * dp, gap = 6 * dp
    let size = CGSize(width: CGFloat(cells.0) * pitch - gap, height: CGFloat(cells.1) * pitch - gap)
    w.dp = dp
    w.cols = cells.0
    w.rows = cells.1
    w.screenSize = CGSize(width: 6 * pitch, height: 12 * pitch)
    w.active = true

    @MainActor func snap() {
        let view = OwlTileView(widget: w).frame(width: size.width, height: size.height).environment(\.owlStatic, true)
        let r = ImageRenderer(content: view)
        r.scale = 1
        guard let img = r.cgImage else {
            FileHandle.standardError.write("owl-render: nothing drawn\n".data(using: .utf8)!)
            exit(1)
        }
        let rep = NSBitmapImageRep(cgImage: img)
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
    }
    // Once to lay it out, so tileWidth and tileHeight are known; then again once the sources had their time.
    snap()
    DispatchQueue.main.asyncAfter(deadline: .now() + wait) { MainActor.assumeIsolated {
        snap()
        if !w.error.isEmpty { FileHandle.standardError.write((w.error + "\n").data(using: .utf8)!) }
        for p in w.problems { FileHandle.standardError.write(("problem: " + p + "\n").data(using: .utf8)!) }
        exit(0)
    } }
}
RunLoop.main.run()
