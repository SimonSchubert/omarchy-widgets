import Foundation
import SwiftUI
import XCTest
@testable import OwlKit

/// The language is held to owl.jar by ../quickshell/test/run.sh, in node and in JavaScriptCore; these check what
/// this runtime adds around it.
@MainActor
final class OwlScriptTests: XCTestCase {
    static let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    static let swiftui = here.deletingLastPathComponent().deletingLastPathComponent()
    static let repo = swiftui.deletingLastPathComponent().deletingLastPathComponent()

    /// The bundled copy is the Quickshell runtime's file, byte for byte: copy it over after changing that one.
    func testBundledOwlJsIsTheQuickshellOne() throws {
        let original = try String(contentsOf: Self.swiftui.deletingLastPathComponent().appendingPathComponent("quickshell/Owl.js"), encoding: .utf8)
        XCTAssertEqual(try OwlScript.bundledSource(), original, "cp runtimes/quickshell/Owl.js runtimes/swiftui/Sources/OwlKit/Resources/Owl.js")
    }

    func testEveryStoreFileCompiles() throws {
        var files = [String]()
        for dir in ["widgets", "faces"] {
            let root = Self.repo.appendingPathComponent(dir).path
            for f in FileManager.default.enumerator(atPath: root)?.compactMap({ $0 as? String }) ?? [] where f.hasSuffix(".owl") {
                files.append(root + "/" + f)
            }
        }
        XCTAssertGreaterThan(files.count, 100)
        let bridge = try OwlBridge(callbacks: .init())
        for f in files {
            let src = try String(contentsOfFile: f, encoding: .utf8)
            if case .failure(let e) = bridge.load(src, persisted: "{}", secrets: "{}") {
                // Above Owl.js's level a file is refused, as an older launcher refuses it.
                XCTAssertTrue(e.message.contains("needs owl") || e.message.contains("owl:"), "\(f): \(e.message)")
            }
        }
    }

    func testRenderHandlersAndState() throws {
        var changed = 0
        var callbacks = OwlBridge.Callbacks()
        callbacks.changed = { changed += 1 }
        callbacks.theme = { $0 == "accent" ? 0xFF7A_A2F7 : nil }
        let bridge = try OwlBridge(callbacks: callbacks)
        let src = """
        widget "t" {
          state n = 0
          Column {
            Text { text: "n ${n}"; color: accent }
            Button { text: "add"; onTap: n = n + 1 }
          }
        }
        """
        guard case .success(let program) = bridge.load(src, persisted: "{}", secrets: "{}") else { return XCTFail("didn't compile") }
        XCTAssertEqual(program.name, "t")
        var tree = try XCTUnwrap(bridge.render(screen: false))
        let column = try XCTUnwrap(tree.root)
        XCTAssertEqual(column.kind, "Column")
        XCTAssertEqual(column.children[0]["text"], .string("n 0"))
        XCTAssertEqual(column.children[0]["color"], .string("#ff7aa2f7"))
        let tap = try XCTUnwrap(column.children[1].handlers["onTap"])
        bridge.handle(tap, [0, 0])
        XCTAssertEqual(changed, 1)
        tree = try XCTUnwrap(bridge.render(screen: false))
        XCTAssertEqual(tree.root?.children[0]["text"], .string("n 1"))
    }

    func testCanvasDrawsInDp() throws {
        let bridge = try OwlBridge(callbacks: .init())
        let src = """
        widget "c" {
          Canvas { rect(0, 0, width / 2, height, fill: "#ff0000"); circle(width / 2, height / 2, 4) }
        }
        """
        guard case .success = bridge.load(src, persisted: "{}", secrets: "{}") else { return XCTFail("didn't compile") }
        let canvas = try XCTUnwrap(bridge.render(screen: false)?.root)
        let ops = bridge.draw(try XCTUnwrap(canvas.draw), width: 100, height: 40)
        XCTAssertEqual(ops.map(\.op), ["rect", "circle"])
        XCTAssertEqual(ops[0].arg(2), 50)
        XCTAssertEqual(ops[0]["fill"], .string("#ffff0000"))
        XCTAssertEqual(ops[1].arg(1), 20)
    }

    func testCompileErrorHasACaret() throws {
        let bridge = try OwlBridge(callbacks: .init())
        guard case .failure(let e) = bridge.load("widget \"x\" { Text { txt: 1 } }", persisted: "{}", secrets: "{}") else { return XCTFail("compiled") }
        XCTAssertTrue(e.message.contains("^"), e.message)
    }

    func testThemeFromToml() {
        let t = OwlTheme(toml: "accent = \"#112233\"\nbackground = \"#000000\"\nforeground = \"#ffffff\"")
        XCTAssertEqual(t.colors["accent"], 0xFF11_2233)
        // Names the file doesn't have are made from the ones it does.
        XCTAssertNotNil(t.colors["surface"])
    }
}

/// Row and Column share their space as Compose does.
@MainActor
final class OwlLayoutTests: XCTestCase {
    func node(_ kind: String, _ p: [String: OwlValue] = [:], _ c: [OwlNode] = [], level: Int = 13) -> OwlNode {
        OwlNode(kind: kind, p: p, children: c, level: level)
    }

    func testTextFillsAColumnButHugsInARow() {
        let text = node("Text", ["text": .string("hi")])
        XCTAssertTrue(OwlRules.wants(text, horizontal: true))
        XCTAssertFalse(OwlRules.wants(text, horizontal: true, hug: true))
        XCTAssertTrue(OwlPlace(text, parentKind: "Column", hug: false, dp: 1).fillW)
        XCTAssertFalse(OwlPlace(text, parentKind: "Row", hug: true, dp: 1).fillW)
    }

    func testWeightsShareWhatIsLeft() {
        let a = node("Box", ["width": .number(40)]), b = node("Box", ["weight": .number(1)]), c = node("Box", ["weight": .number(3)])
        let places = [a, b, c].map { OwlPlace($0, parentKind: "Row", hug: true, dp: 1) }
        XCTAssertEqual(places.map(\.weight), [0, 1, 3])
        XCTAssertEqual(places[0].prefW, 40)
    }

    func testCanvasFillsUnlessSized() {
        XCTAssertTrue(OwlRules.wants(node("Canvas"), horizontal: false))
        XCTAssertFalse(OwlRules.wants(node("Canvas", ["height": .number(20)]), horizontal: true))
    }

    func testReversedLazyGridPutsTheShortRowOnTop() {
        let kids = (0..<5).map { node("Text", ["text": .string("\($0)")]) }
        let grid = node("Grid", ["lazy": .bool(true), "reverse": .bool(true), "columns": .number(2)], kids)
        XCTAssertEqual(OwlRules.ordered(grid).map { $0?["text"].string }, ["4", nil, "2", "3", "0", "1"])
    }
}

/// How long an animated Canvas takes a frame in Owl.js: run with JSC_useJIT=false to see an iOS app's.
@MainActor
final class OwlFrameTimeTests: XCTestCase {
    func testKoiPondFrameTime() throws {
        let file = OwlScriptTests.repo.appendingPathComponent("widgets/simonschubert/koi-pond/widget.owl")
        let src = try String(contentsOf: file, encoding: .utf8)
        let bridge = try OwlBridge(callbacks: .init())
        guard case .success = bridge.load(src, persisted: "{}", secrets: "{}") else { return XCTFail("didn't compile") }
        guard let canvas = Self.firstCanvas(bridge.render(screen: false)?.root) else { return XCTFail("no Canvas") }
        let frames = 120
        let start = Date()
        var ops = 0
        for i in 0..<frames {
            bridge.frame(Double(i) / 60)
            ops += Self.count(bridge.draw(canvas, width: 200, height: 130))
        }
        let ms = Date().timeIntervalSince(start) * 1000 / Double(frames)
        print(String(format: "koi-pond: %.2f ms a frame, %d drawing calls, JIT %@", ms, ops / frames,
                     ProcessInfo.processInfo.environment["JSC_useJIT"] == "false" ? "off" : "on"))
        XCTAssertGreaterThan(ops, 0)
    }

    static func count(_ ops: [OwlDrawOp]) -> Int { ops.reduce(0) { $0 + 1 + count($1.ops) } }

    static func firstCanvas(_ n: OwlNode?) -> Int? {
        guard let n else { return nil }
        if let d = n.draw { return d }
        for c in n.children { if let d = firstCanvas(c) { return d } }
        return nil
    }
}
