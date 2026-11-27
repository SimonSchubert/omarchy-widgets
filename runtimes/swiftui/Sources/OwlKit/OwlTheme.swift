import Foundation
import SwiftUI

/// OWL's theme names (accent, background, color4, lighter_background...) to ARGB, as Owl.themeFromToml reads
/// them from an Omarchy colors.toml.
public struct OwlTheme: Equatable {
    public var colors: [String: UInt32]

    public init(colors: [String: UInt32]) { self.colors = colors }

    /// From an Omarchy colors.toml's text; "" gives Owl.js's own default, Tokyo Night.
    @MainActor
    public init(toml: String) {
        let script = try? OwlScript()
        let t = script?.owl.invokeMethod("themeFromToml", withArguments: [toml])
        colors = Self.palette(t?.toDictionary() ?? [:])
    }

    /// Omarchy's current theme where there is one, else Tokyo Night.
    @MainActor
    public static func current() -> OwlTheme {
        let path = NSHomeDirectory() + "/.local/state/omarchy/current/theme/colors.toml"
        return OwlTheme(toml: (try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
    }

    static func palette(_ d: [AnyHashable: Any]) -> [String: UInt32] {
        var out = [String: UInt32]()
        for (k, v) in d {
            if let k = k as? String, let n = v as? NSNumber { out[k] = UInt32(truncatingIfNeeded: n.int64Value) }
        }
        return out
    }

    public func argb(_ name: String) -> UInt32 { colors[name] ?? 0xFF88_8888 }

    public func color(_ name: String) -> Color { Color(argb: argb(name)) }
}

extension Color {
    init(argb: UInt32) {
        self.init(.sRGB,
                  red: Double((argb >> 16) & 0xFF) / 255,
                  green: Double((argb >> 8) & 0xFF) / 255,
                  blue: Double(argb & 0xFF) / 255,
                  opacity: Double((argb >> 24) & 0xFF) / 255)
    }

    /// "#aarrggbb", as Owl.js writes colors; also #rrggbb.
    init?(owl text: String) {
        guard text.hasPrefix("#") else { return nil }
        let hex = text.dropFirst()
        guard let n = UInt32(hex, radix: 16) else { return nil }
        if hex.count == 8 { self.init(argb: n) }
        else if hex.count == 6 { self.init(argb: 0xFF00_0000 | n) }
        else { return nil }
    }
}

extension OwlValue {
    /// A color property: "#aarrggbb", or nil for null, a gradient or anything else.
    var color: Color? { string.flatMap { Color(owl: $0) } }

    /// A gradient property: {gradient: {radial, coords, colors}}.
    var gradient: OwlGradient? {
        let g = self["gradient"]
        guard g.object != nil else { return nil }
        return OwlGradient(radial: g["radial"].isTrue, coords: (g["coords"].list ?? []).map { $0.number ?? 0 },
                           colors: (g["colors"].list ?? []).map { $0.color })
    }
}

public struct OwlGradient {
    var radial: Bool
    var coords: [Double]
    var colors: [Color?]

    var stops: Gradient {
        let n = colors.count
        return Gradient(stops: colors.enumerated().compactMap { i, c in
            c.map { Gradient.Stop(color: $0, location: n == 1 ? 0 : Double(i) / Double(n - 1)) }
        })
    }

    func coord(_ i: Int) -> Double { i < coords.count ? coords[i] : 0 }
}
