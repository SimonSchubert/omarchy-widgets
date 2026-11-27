import Foundation
import SwiftUI

/// A property's value as Owl.js renders it: colors are "#aarrggbb" text, a gradient {gradient: {...}}.
public enum OwlValue: Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case list([OwlValue])
    case object([String: OwlValue])

    init(_ any: Any?) {
        switch any {
        case nil, is NSNull: self = .null
        case let n as NSNumber:
            self = CFGetTypeID(n) == CFBooleanGetTypeID() ? .bool(n.boolValue) : .number(n.doubleValue)
        case let s as String: self = .string(s)
        case let a as [Any]: self = .list(a.map { OwlValue($0) })
        case let d as [String: Any]: self = .object(d.mapValues { OwlValue($0) })
        default: self = .null
        }
    }

    public var number: Double? {
        if case .number(let n) = self, n.isFinite { return n }
        return nil
    }
    public var string: String? {
        if case .string(let s) = self { return s }
        return nil
    }
    public var bool: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }
    public var list: [OwlValue]? {
        if case .list(let l) = self { return l }
        return nil
    }
    public var object: [String: OwlValue]? {
        if case .object(let o) = self { return o }
        return nil
    }
    public var isNull: Bool { self == .null }
    /// true and nothing else, as `p.x === true` reads.
    public var isTrue: Bool { self == .bool(true) }

    public subscript(key: String) -> OwlValue {
        object?[key] ?? .null
    }

    public subscript(index: Int) -> OwlValue {
        guard let l = list, index >= 0, index < l.count else { return .null }
        return l[index]
    }
}

/// One node of the tree Owl.js renders: kind, properties, handlers by number, children.
public struct OwlNode: Equatable {
    public var kind: String
    public var p: [String: OwlValue]
    /// `animate x: ...`, by property.
    public var a: [String: OwlValue]
    public var children: [OwlNode]
    /// The file's owl level, which decides how a Text in a Row is laid out.
    public var level: Int
    /// A Box that a component used with weight: or padding: is wrapped in.
    public var wrapper: Bool
    /// onTap, onChange...: the number OwlBridge.handle runs.
    public var handlers: [String: Int]
    /// A Canvas's drawing, by number.
    public var draw: Int?

    init(_ d: [String: Any]) {
        kind = d["k"] as? String ?? ""
        p = (d["p"] as? [String: Any] ?? [:]).mapValues { OwlValue($0) }
        a = (d["a"] as? [String: Any] ?? [:]).mapValues { OwlValue($0) }
        children = (d["c"] as? [[String: Any]] ?? []).map { OwlNode($0) }
        level = d["l"] as? Int ?? 1
        wrapper = d["w"] as? Bool ?? false
        handlers = (d["h"] as? [String: Any] ?? [:]).compactMapValues { $0 as? Int }
        draw = d["d"] as? Int
    }

    public init(kind: String, p: [String: OwlValue] = [:], children: [OwlNode] = [], level: Int = 1) {
        self.kind = kind
        self.p = p
        a = [:]
        self.children = children
        self.level = level
        wrapper = false
        handlers = [:]
        draw = nil
    }

    public subscript(prop: String) -> OwlValue { p[prop] ?? .null }

    /// `visible:` unset, null or true.
    public var shown: Bool {
        let v = self["visible"]
        return v.isNull || v.isTrue
    }

    /// Equal for drawing: handler numbers change on every render without changing what they do.
    public static func == (x: OwlNode, y: OwlNode) -> Bool {
        x.kind == y.kind && x.p == y.p && x.a == y.a && x.level == y.level && x.wrapper == y.wrapper
            && x.children == y.children && Set(x.handlers.keys) == Set(y.handlers.keys) && (x.draw == nil) == (y.draw == nil)
    }
}

/// A rendered tile, or the full-screen view a widget opens with screen().
public struct OwlTree {
    public var children: [OwlNode]
    /// Whether anything read `time`: then each frame renders again.
    public var readsTime: Bool
    public var padding: Double
    public var background: OwlValue
    public var statusBar: Bool
    public var onTap: Int?
    public var title: String?

    init(_ d: [String: Any]) {
        children = (d["children"] as? [[String: Any]] ?? []).map { OwlNode($0) }
        readsTime = d["readsTime"] as? Bool ?? false
        padding = (d["padding"] as? NSNumber)?.doubleValue ?? 12
        background = OwlValue(d["background"])
        statusBar = d["statusBar"] as? Bool ?? true
        onTap = d["onTap"] as? Int
        title = d["title"] as? String
    }

    /// The one node a tile draws: its only child, or a Column of them.
    public var root: OwlNode? {
        if children.isEmpty { return nil }
        if children.count == 1 { return children[0] }
        return OwlNode(kind: "Column", p: ["gap": .number(0)], children: children, level: children[0].level)
    }
}

/// One drawing call of a Canvas frame, from Instance.draw: {op, args, fill, stroke, ..., ops: [...]}.
public struct OwlDrawOp {
    public var op: String
    public var args: [Double?]
    public var named: [String: OwlValue]
    public var ops: [OwlDrawOp]

    init?(_ any: Any) {
        guard let d = any as? [String: Any], let op = d["op"] as? String else { return nil }
        self.op = op
        args = (d["args"] as? [Any] ?? []).map { ($0 as? NSNumber).flatMap { CFGetTypeID($0) == CFBooleanGetTypeID() ? nil : $0.doubleValue } }
        var named = [String: OwlValue]()
        for (k, v) in d where k != "op" && k != "args" && k != "ops" { named[k] = OwlValue(v) }
        self.named = named
        ops = (d["ops"] as? [Any] ?? []).compactMap { OwlDrawOp($0) }
    }

    public func arg(_ i: Int) -> Double {
        i < args.count ? (args[i].flatMap { $0.isFinite ? $0 : nil } ?? 0) : 0
    }

    public subscript(key: String) -> OwlValue { named[key] ?? .null }
}
