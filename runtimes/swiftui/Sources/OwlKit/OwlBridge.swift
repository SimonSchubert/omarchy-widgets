import Foundation
import JavaScriptCore

/// One widget's Owl.js Instance, seen from Swift. What crosses between the two is JSON text, once per render
/// and once per Canvas frame, rather than a property read across the bridge per value; handlers and Canvas
/// drawings stay closures in JavaScript and are handed to Swift as numbers.
@MainActor
final class OwlBridge {
    let script: OwlScript
    private let glue: JSValue

    /// What the instance calls back into: `OwlWidget` sets these.
    struct Callbacks {
        var theme: (String) -> UInt32? = { _ in nil }
        var tile: (String) -> Any? = { _ in nil }
        var act: (String, [String?]) -> Void = { _, _ in }
        var runInto: (String, Int) -> Void = { _, _ in }
        /// url, body text, whether it's JSON, headers, the slot for the answer or -1, method.
        var post: (String, String, Bool, [String: String], Int, String) -> Void = { _, _, _, _, _, _ in }
        var report: (String) -> Void = { _ in }
        var changed: () -> Void = {}
    }

    init(callbacks: Callbacks) throws {
        script = try OwlScript()
        let ctx = script.context
        ctx.evaluateScript(Self.source, withSourceURL: URL(fileURLWithPath: "OwlBridge.js"))
        if let e = script.take() { throw OwlScriptError("OwlBridge.js: \(e)") }
        let swift = JSValue(newObjectIn: ctx)!
        let theme: @convention(block) (String) -> JSValue = { name in
            guard let v = callbacks.theme(name) else { return JSValue(nullIn: ctx) }
            return JSValue(double: Double(v), in: ctx)
        }
        let tile: @convention(block) (String) -> JSValue = { name in
            guard let v = callbacks.tile(name) else { return JSValue(nullIn: ctx) }
            return JSValue(object: v, in: ctx)
        }
        let act: @convention(block) (String, JSValue) -> Void = { name, args in
            let list = (args.toArray() ?? []).map { $0 is NSNull ? nil : "\($0)" }
            callbacks.act(name, list)
        }
        let runInto: @convention(block) (String, Int) -> Void = { callbacks.runInto($0, $1) }
        let post: @convention(block) (String, String, Bool, String, Int, String) -> Void = { url, body, json, headers, slot, method in
            let h = (try? JSONSerialization.jsonObject(with: Data(headers.utf8)) as? [String: Any]) ?? [:]
            callbacks.post(url, body, json, h.mapValues { "\($0)" }, slot, method)
        }
        let report: @convention(block) (String) -> Void = { callbacks.report($0) }
        let changed: @convention(block) () -> Void = { callbacks.changed() }
        swift.setObject(theme, forKeyedSubscript: "theme" as NSString)
        swift.setObject(tile, forKeyedSubscript: "tile" as NSString)
        swift.setObject(act, forKeyedSubscript: "act" as NSString)
        swift.setObject(runInto, forKeyedSubscript: "runInto" as NSString)
        swift.setObject(post, forKeyedSubscript: "post" as NSString)
        swift.setObject(report, forKeyedSubscript: "report" as NSString)
        swift.setObject(changed, forKeyedSubscript: "changed" as NSString)
        glue = ctx.objectForKeyedSubscript("OwlBridge").construct(withArguments: [script.owl as Any, swift])
    }

    @discardableResult
    private func call(_ name: String, _ args: [Any] = []) -> JSValue? {
        let r = glue.invokeMethod(name, withArguments: args)
        if let e = script.take() {
            // Owl.js guards what a widget does; what gets here is this runtime's own mistake.
            let stack = e.objectForKeyedSubscript("stack")?.toString() ?? ""
            NSLog("OwlKit: %@ threw %@\n%@", name, e.toString(), stack)
            return nil
        }
        return r
    }

    private func json(_ name: String, _ args: [Any] = []) -> Any? {
        guard let s = call(name, args)?.toString(), let d = s.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: d, options: [.fragmentsAllowed])
    }

    /// Compiles [source]. The program's facts, or the error as `owl check` words it, caret and all.
    func load(_ source: String, persisted: String, secrets: String) -> Result<OwlProgram, OwlLoadError> {
        guard let r = json("load", [source, persisted, secrets]) as? [String: Any] else { return .failure(OwlLoadError(message: "Owl.js gave nothing back")) }
        if let e = r["error"] as? String { return .failure(OwlLoadError(message: e)) }
        return .success(OwlProgram(r["program"] as? [String: Any] ?? [:]))
    }

    func sources() -> [OwlSourceSpec] {
        ((json("sources") as? [[String: Any]]) ?? []).enumerated().map { OwlSourceSpec(index: $0.offset, $0.element) }
    }

    func sourceArg(_ index: Int) -> String { call("sourceArg", [index])?.toString() ?? "" }
    func sourceHeaders(_ index: Int) -> [String: String] {
        ((json("sourceHeaders", [index]) as? [String: Any]) ?? [:]).mapValues { "\($0)" }
    }

    /// `every Ns { }` triggers: their index and seconds.
    func everyTriggers() -> [(index: Int, seconds: Double)] {
        ((json("everyTriggers") as? [[String: Any]]) ?? []).map { ($0["index"] as? Int ?? 0, ($0["seconds"] as? NSNumber)?.doubleValue ?? 60) }
    }

    func hasAt() -> Bool { call("hasAt")?.toBool() ?? false }

    func render(screen: Bool) -> OwlTree? {
        guard let r = json("render", [screen]) as? [String: Any] else { return nil }
        return OwlTree(r)
    }

    /// A Canvas's drawing calls for this frame, in dp.
    func draw(_ id: Int, width: Double, height: Double) -> [OwlDrawOp] {
        ((json("draw", [id, width, height]) as? [Any]) ?? []).compactMap { OwlDrawOp($0) }
    }

    /// Runs a handler with plain arguments (numbers and text).
    func handle(_ id: Int, _ args: [Any]) { call("handle", [id, args]) }

    /// A source's text (cmd, stream, http, file), parsed by the instance if the source says json.
    func setSourceText(_ slot: Int, _ text: String) { call("setSourceText", [slot, text]) }
    /// A source's value, as JSON (clock, android.*), or null.
    func setSourceJSON(_ slot: Int, _ json: String) { call("setSourceJSON", [slot, json]) }
    /// A `status` source: {out, err, code, ok}.
    func setSourceStatus(_ slot: Int, code: Int, out: String, err: String, json: Bool, ok: Bool) {
        call("setSourceStatus", [slot, code, out, err, json, ok])
    }
    func setStateText(_ slot: Int, _ text: String) { call("setStateText", [slot, text]) }
    /// post()'s answer into its state: {code, ok, out}.
    func setPostAnswer(_ slot: Int, code: Int, text: String) { call("setPostAnswer", [slot, code, text]) }

    func invalidate() { call("invalidate") }
    func checkTriggers() { call("checkTriggers") }
    func fire(_ index: Int) { call("fire", [index]) }
    func tick(_ now: Double) { call("tick", [now]) }
    func frame(_ seconds: Double) { call("frame", [seconds]) }
    func persisted() -> String { call("persisted")?.toString() ?? "{}" }
    func secrets() -> String { call("secrets")?.toString() ?? "{}" }


    static let source = #"""
    function OwlBridge(Owl, swift) {
      this.Owl = Owl
      this.swift = swift
      this.instance = null
      this.specs = []
      // Handlers and drawings by number: this render's and the last one's, so a tap on a view that's
      // about to be replaced still lands.
      this.fns = {}
      this.lastFns = {}
      this.next = 1
      var self = this
      this.host = {
        theme: function(n) { return swift.theme(n) },
        tile: function(n) { return swift.tile(n) },
        act: function(name, args) {
          swift.act(name, (args || []).map(function(v) { return v === null || v === undefined ? null : Owl.show(v) }))
        },
        runInto: function(cmd, slot) { swift.runInto(String(cmd), slot) },
        // A map or list body goes as JSON, anything else as its text.
        post: function(url, body, headers, slot, method) {
          var json = Array.isArray(body) || body instanceof Map
          var text = json ? JSON.stringify(Owl.toJson(body)) : body === null || body === undefined ? "" : Owl.show(body)
          swift.post(String(url), text, json, JSON.stringify(headers || {}), slot === null || slot === undefined ? -1 : slot, method || "POST")
        },
        report: function(m) { swift.report(String(m)) },
        changed: function() { swift.changed() }
      }
    }

    OwlBridge.prototype = {
      load: function(src, persisted, secrets) {
        var Owl = this.Owl
        var program
        try {
          program = Owl.compile(src)
        } catch (e) {
          return JSON.stringify({ error: Owl.formatError(src, e) })
        }
        var p = {}, s = {}
        try { p = JSON.parse(persisted) } catch (e) {}
        try { s = JSON.parse(secrets) } catch (e) {}
        this.instance = new Owl.Instance(program, this.host, p, s)
        this.specs = this.instance.sources()
        return JSON.stringify({ program: {
          name: program.name, size: program.size, minSize: program.minSize, page: program.page, order: program.order,
          padding: program.padding, isFace: !!program.isFace, level: program.level, animated: !!program.animated,
          hasScreen: !!program.screen, kind: program.kind, needsLinux: !!program.needsLinux
        } })
      },

      sources: function() {
        return JSON.stringify(this.specs.map(function(s) {
          return { slot: s.slot, name: s.name, kind: s.kind, every: s.every, json: !!s.json, timeout: s.timeout,
            status: !!s.status, optional: !!s.optional }
        }))
      },
      sourceArg: function(i) { return String(this.specs[i].arg()) },
      sourceHeaders: function(i) { return JSON.stringify(this.specs[i].headers() || {}) },
      everyTriggers: function() { return JSON.stringify(this.instance ? this.instance.everyTriggers() : []) },
      hasAt: function() { return !!this.instance && this.instance.hasAt() },

      keep: function(f) {
        var id = this.next++
        this.fns[id] = f
        return id
      },

      plainNode: function(n) {
        var self = this
        var out = { k: n.kind, p: n.p, a: n.a, l: n.level }
        if (n.wrapper) out.w = true
        var h = null
        for (var name in n.h) {
          h = h || {}
          h[name] = this.keep(n.h[name])
        }
        if (h) out.h = h
        if (n.draw) out.d = this.keep(n.draw)
        if (n.c && n.c.length) out.c = n.c.map(function(c) { return self.plainNode(c) })
        return out
      },

      render: function(screen) {
        if (!this.instance) return "null"
        var self = this
        this.lastFns = this.fns
        this.fns = {}
        var t = this.instance.render(screen)
        return JSON.stringify({
          children: t.children.map(function(c) { return self.plainNode(c) }),
          readsTime: !!t.readsTime, padding: t.padding, background: t.background, statusBar: t.statusBar !== false,
          onTap: t.onTap ? this.keep(t.onTap) : null, title: t.title === undefined ? null : t.title
        })
      },

      fn: function(id) { return this.fns[id] || this.lastFns[id] || null },
      handle: function(id, args) {
        var f = this.fn(id)
        if (f) f.apply(null, args)
      },
      draw: function(id, w, h) {
        var f = this.fn(id)
        return JSON.stringify(f ? f(w, h) : [])
      },

      setSourceText: function(slot, text) { if (this.instance) this.instance.setSource(slot, text) },
      setSourceJSON: function(slot, json) {
        if (!this.instance) return
        var v = null
        try { v = this.Owl.fromJson(JSON.parse(json)) } catch (e) { this.host.report("not JSON: " + String(json).slice(0, 80)) }
        this.instance.setSource(slot, v)
      },
      setSourceStatus: function(slot, code, text, err, json, ok) {
        if (!this.instance) return
        var out = text
        if (json) { try { out = this.Owl.parseJson(String(text).trim()) } catch (e) { out = null } }
        else out = String(text).replace(/\s+$/, "")
        this.instance.setSource(slot, new Map([["out", out], ["err", String(err || "").replace(/\s+$/, "")], ["code", code], ["ok", !!ok]]))
      },
      setStateText: function(slot, text) { if (this.instance) this.instance.setState(slot, String(text).replace(/\s+$/, "")) },
      setPostAnswer: function(slot, code, text) {
        if (!this.instance) return
        var out = null
        if (text !== "") { try { out = this.Owl.parseJson(text.trim()) } catch (e) { out = text } }
        this.instance.setState(slot, new Map([["code", code], ["ok", code >= 200 && code < 300], ["out", out]]))
      },

      invalidate: function() { if (this.instance) this.instance.invalidate() },
      checkTriggers: function() { if (this.instance) this.instance.checkTriggers() },
      fire: function(i) { if (this.instance) this.instance.fire(i) },
      tick: function(now) { if (this.instance) this.instance.tick(now) },
      frame: function(t) { if (this.instance) this.instance.frame(t) },
      persisted: function() { return JSON.stringify(this.instance ? this.instance.persisted() : {}) },
      secrets: function() { return JSON.stringify(this.instance ? this.instance.secrets() : {}) }
    }
    """#
}

public struct OwlLoadError: Error { public let message: String }

/// What a compiled file says about itself.
public struct OwlProgram: Equatable {
    public var name: String
    /// Cells, columns × rows; nil when the file doesn't say.
    public var size: (Int, Int)?
    public var minSize: (Int, Int)
    public var page: Int
    public var order: Int
    /// Around the tile's content, in dp.
    public var padding: Double
    public var isFace: Bool
    public var level: Int
    public var animated: Bool
    public var hasScreen: Bool
    public var kind: String

    init(_ d: [String: Any]) {
        func cells(_ v: Any?) -> (Int, Int)? {
            guard let a = v as? [NSNumber], a.count == 2 else { return nil }
            return (a[0].intValue, a[1].intValue)
        }
        name = d["name"] as? String ?? "widget"
        size = cells(d["size"])
        minSize = cells(d["minSize"]) ?? (1, 1)
        page = d["page"] as? Int ?? 1
        order = d["order"] as? Int ?? 0
        padding = (d["padding"] as? NSNumber)?.doubleValue ?? 12
        isFace = d["isFace"] as? Bool ?? false
        level = d["level"] as? Int ?? 1
        animated = d["animated"] as? Bool ?? false
        hasScreen = d["hasScreen"] as? Bool ?? false
        kind = d["kind"] as? String ?? "widget"
    }

    public static func == (a: OwlProgram, b: OwlProgram) -> Bool {
        a.name == b.name && a.size?.0 == b.size?.0 && a.size?.1 == b.size?.1 && a.level == b.level && a.isFace == b.isFace
            && a.padding == b.padding && a.animated == b.animated && a.hasScreen == b.hasScreen
    }
}

/// One `source` of a widget, for [OwlSources] to run.
struct OwlSourceSpec {
    let index: Int
    let slot: Int
    let name: String
    let kind: String
    let every: Double?
    let json: Bool
    let timeout: Double?
    let status: Bool

    init(index: Int, _ d: [String: Any]) {
        self.index = index
        slot = d["slot"] as? Int ?? 0
        name = d["name"] as? String ?? ""
        kind = d["kind"] as? String ?? ""
        every = (d["every"] as? NSNumber)?.doubleValue
        json = d["json"] as? Bool ?? false
        timeout = (d["timeout"] as? NSNumber)?.doubleValue
        status = d["status"] as? Bool ?? false
    }
}
