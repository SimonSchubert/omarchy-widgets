import Foundation
import JavaScriptCore

/// Owl.js, the language, loaded into a JavaScriptCore context: the same file the Quickshell runtime runs,
/// so a new owl level lands in one place. Everything Swift does with OWL goes through [owl], its exports.
///
/// A context is one thread's: make and use it on the main actor.
public final class OwlScript {
    public let context: JSContext
    /// Owl.js's `module.exports`: compile, Instance, show, themeFromToml...
    public let owl: JSValue
    /// The last exception thrown into Swift, cleared by [take].
    private var thrown: JSValue?

    /// Where named time zones are read from, as on Linux; nil leaves Owl.js only offsets and the local zone.
    public static var zoneDir = "/usr/share/zoneinfo"

    public init(source: String? = nil) throws {
        guard let context = JSContext() else { throw OwlScriptError("no JavaScriptCore context") }
        self.context = context
        let src = try source ?? Self.bundledSource()
        var caught: JSValue?
        context.exceptionHandler = { _, e in caught = e }
        // QML's `.pragma library` is a syntax error here, and `module` is what node gives the exports through.
        context.evaluateScript("var module = { exports: {} };")
        context.evaluateScript(src.replacingOccurrences(of: ".pragma library", with: "//", options: .anchored), withSourceURL: URL(fileURLWithPath: "Owl.js"))
        if let e = caught { throw OwlScriptError("Owl.js: \(e)") }
        owl = context.objectForKeyedSubscript("module").objectForKeyedSubscript("exports")
        context.exceptionHandler = nil
        installZoneReader()
        context.exceptionHandler = { [unowned self] _, e in self.thrown = e }
    }

    /// Owl.js as this package bundles it.
    public static func bundledSource() throws -> String {
        guard let url = Bundle.module.url(forResource: "Owl", withExtension: "js") else { throw OwlScriptError("Owl.js is not in the bundle") }
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// The exception the last call threw, if any, and forgets it.
    public func take() -> JSValue? {
        defer { thrown = nil }
        return thrown
    }

    /// Calls `owl.<name>(args)`, throwing what it throws.
    @discardableResult
    public func call(_ name: String, _ args: [Any]) throws -> JSValue {
        let r = owl.invokeMethod(name, withArguments: args)!
        if let e = take() { throw OwlScriptError.from(e) }
        return r
    }

    private func installZoneReader() {
        let ctx = context
        let read: @convention(block) (String) -> JSValue = { name in
            // Names come from widgets: keep them inside the zone folder.
            guard !name.contains(".."), let data = FileManager.default.contents(atPath: Self.zoneDir + "/" + name) else { return JSValue(nullIn: ctx) }
            return Self.bytes(data, in: ctx)
        }
        owl.invokeMethod("setZoneReader", withArguments: [read])
    }

    /// A Uint8Array holding [data].
    static func bytes(_ data: Data, in ctx: JSContext) -> JSValue {
        let array = ctx.objectForKeyedSubscript("Uint8Array").construct(withArguments: [data.count])!
        // Through a plain list once rather than a property set per byte.
        array.invokeMethod("set", withArguments: [Array(data).map { Int($0) }])
        return array
    }
}

public struct OwlScriptError: Error, CustomStringConvertible {
    public let description: String
    /// The `message` of a CompileError or WidgetError, as Owl.js words it.
    public let message: String
    /// A CompileError's position in the source, if it has one.
    public let pos: Int?
    /// The JavaScript value thrown, for formatError.
    public let value: JSValue?

    init(_ text: String) {
        description = text
        message = text
        pos = nil
        value = nil
    }

    init(value: JSValue) {
        let m = value.objectForKeyedSubscript("message")
        message = m?.isUndefined == false ? m!.toString() : value.toString()
        let p = value.objectForKeyedSubscript("pos")
        pos = p?.isNumber == true ? Int(p!.toInt32()) : nil
        description = message
        self.value = value
    }

    static func from(_ e: JSValue) -> OwlScriptError { OwlScriptError(value: e) }
}
