// A board of OWL widgets in a window, with nothing but OwlKit:
//
//   swift run OwlBoard                              # every face and widget in this repo
//   OWL_WIDGETS=~/my-widgets swift run OwlBoard     # a folder of your own
//   OWL_THEME=path/to/colors.toml swift run OwlBoard
//
// It draws every .owl file it finds on the launcher's 6-column grid, in the Omarchy theme when there is one
// (Tokyo Night otherwise), and saves what they persist under ~/Library/Application Support/owl. A face takes
// the board's whole width and a window's height, as it takes a whole home page. An app that embeds OwlKit
// does what this file does.
import AppKit
import OwlKit
import SwiftUI

@MainActor
final class Board: ObservableObject {
    let host = OwlHost()
    @Published var widgets: [OwlWidget] = []
    var theme: OwlTheme

    init() {
        let env = ProcessInfo.processInfo.environment
        if let t = env["OWL_THEME"], let text = try? String(contentsOfFile: (t as NSString).expandingTildeInPath, encoding: .utf8) {
            theme = OwlTheme(toml: text)
        } else {
            theme = OwlTheme.current()
        }
        let dirs = env["OWL_WIDGETS"].map { [($0 as NSString).expandingTildeInPath] } ?? Self.repoDirs()
        let files = dirs.flatMap(Self.owlFiles)
        widgets = files.map { OwlWidget(path: $0, host: host, theme: theme) }
    }

    /// This repo's faces/ and widgets/, found from where `swift run` runs or from the binary.
    static func repoDirs() -> [String] {
        var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<6 {
            let widgets = dir.appendingPathComponent("widgets").path
            if FileManager.default.fileExists(atPath: widgets) && FileManager.default.fileExists(atPath: dir.appendingPathComponent("index.json").path) {
                return [dir.appendingPathComponent("faces").path, widgets]
            }
            dir.deleteLastPathComponent()
        }
        return []
    }

    static func owlFiles(_ dir: String) -> [String] {
        guard let e = FileManager.default.enumerator(atPath: dir) else { return [] }
        return e.compactMap { $0 as? String }.filter { $0.hasSuffix(".owl") && !$0.contains("/.") }.sorted().map { dir + "/" + $0 }
    }
}

struct BoardView: View {
    @ObservedObject var board: Board
    let gap: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let pitch = (geo.size.width - 2 * 12 + gap) / 6
            // The launcher's cell is 69 dp; a widget is drawn at the scale that gives it the same one here.
            let dp = pitch / 69
            let places = place(rowsInWindow: max(1, Int(geo.size.height / pitch)))
            let rows = places.map { $0.y + $0.h }.max() ?? 0
            ScrollView {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(board.widgets.enumerated()), id: \.element.id) { i, w in
                        let p = places[i]
                        OwlTileView(widget: w)
                            .frame(width: CGFloat(p.w) * pitch - gap, height: CGFloat(p.h) * pitch - gap)
                            .offset(x: CGFloat(p.x) * pitch, y: CGFloat(p.y) * pitch)
                            .onAppear { configure(w, p, dp: dp, screen: geo.size) }
                            .onChange(of: dp) { _, dp in configure(w, p, dp: dp, screen: geo.size) }
                            .onChange(of: geo.size) { _, s in configure(w, p, dp: dp, screen: s) }
                    }
                }
                .frame(width: geo.size.width - 24, height: CGFloat(rows) * pitch, alignment: .topLeading)
                .padding(12)
            }
        }
        .background(board.theme.color("background"))
    }

    private func configure(_ w: OwlWidget, _ p: Place, dp: CGFloat, screen: CGSize) {
        w.dp = dp
        w.cols = p.w
        w.rows = p.h
        w.screenSize = screen
        w.active = true
    }

    struct Place { var x, y, w, h: Int }

    /// First fit at each widget's own size, in file order.
    private func place(rowsInWindow: Int) -> [Place] {
        var used = [[Bool]]()
        var out = [Place]()
        func free(_ x: Int, _ y: Int) -> Bool { y < used.count ? !used[y][x] : true }
        for w in board.widgets {
            let size = w.program == nil ? (3, 2) : w.isFace ? (6, rowsInWindow) : w.size
            let cw = min(max(size.0, 1), 6), ch = max(size.1, 1)
            var y = 0
            search: while true {
                for x in 0...(6 - cw) {
                    var ok = true
                    for yy in y..<(y + ch) where ok { for xx in x..<(x + cw) where !free(xx, yy) { ok = false; break } }
                    if !ok { continue }
                    while used.count < y + ch { used.append([Bool](repeating: false, count: 6)) }
                    for yy in y..<(y + ch) { for xx in x..<(x + cw) { used[yy][xx] = true } }
                    out.append(Place(x: x, y: y, w: cw, h: ch))
                    break search
                }
                y += 1
            }
        }
        return out
    }
}

struct OwlBoardApp: App {
    @StateObject private var board = Board()

    var body: some Scene {
        WindowGroup("owl") {
            BoardView(board: board).frame(minWidth: 360, minHeight: 480)
        }
        .defaultSize(width: 480, height: 900)
    }
}

// `swift run` starts a bare executable: make it a regular app with a Dock icon and a window in front.
NSApplication.shared.setActivationPolicy(.regular)
DispatchQueue.main.async { NSApplication.shared.activate(ignoringOtherApps: true) }
OwlBoardApp.main()
