import SwiftUI

// How an OWL node sits in its parent: the launcher's rules (widgets/render/Render.kt in omarchy-proot), as
// ../quickshell/OwlLayout.js has them. A node wraps its content unless it fills. Text without width, weight
// or fill takes the full width; Progress, Sparkline, Grid, Slider and Input take the width; Canvas, Shader and
// Terminal take all the space. A Row, Column or Box is as wide as a child that fills makes it, and only that
// wide otherwise -- so `justify: end` in a Row of Buttons does nothing, as on the launcher.

enum OwlRules {
    static let sizing = ["width", "height", "size", "fill", "weight"]

    static func sized(_ n: OwlNode) -> Bool { sizing.contains { !n[$0].isNull } }

    /// `padding: 8`, `[h, v]` or `[l, t, r, b]` as (l, t, r, b), in dp.
    static func padding(_ v: OwlValue) -> (Double, Double, Double, Double) {
        if let n = v.number { return (n, n, n, n) }
        if let l = v.list {
            if l.count == 2 { return (l[0].number ?? 0, l[1].number ?? 0, l[0].number ?? 0, l[1].number ?? 0) }
            if l.count == 4 { return (l[0].number ?? 0, l[1].number ?? 0, l[2].number ?? 0, l[3].number ?? 0) }
        }
        return (0, 0, 0, 0)
    }

    /// Width and height a node asked for in dp, or -1.
    static func fixedWidth(_ n: OwlNode) -> Double { n["width"].number ?? n["size"].number ?? -1 }
    static func fixedHeight(_ n: OwlNode) -> Double { n["height"].number ?? n["size"].number ?? -1 }
    static func weight(_ n: OwlNode) -> Double { n["weight"].number ?? 0 }

    /// Whether [node] reaches for all the width (`horizontal`) or height it is given. [hug] is set for the
    /// children of a Row or Flow in a file of owl 10 or later, where a Text is as wide as its text, and for
    /// those of a Column that hugs.
    static func wants(_ node: OwlNode, horizontal: Bool, hug: Bool = false) -> Bool {
        let fill = node["fill"]
        if fill.isTrue || fill.string == (horizontal ? "width" : "height") { return true }
        if fixedWidth(node) >= 0 && horizontal { return false }
        if fixedHeight(node) >= 0 && !horizontal { return false }
        let k = node.kind
        if k == "Canvas" || k == "Shader" || k == "Terminal" { return !sized(node) }
        let container = k == "Column" || k == "Row" || k == "Box" || k == "Flow"
        if !horizontal {
            guard container else { return false }
            return node.children.contains { (k == "Column" && weight($0) > 0) || wants($0, horizontal: false) }
        }
        if k == "Text" { return node["weight"].isNull && !hug }
        if ["Progress", "Sparkline", "Grid", "Slider", "Input"].contains(k) { return !sized(node) }
        // A Popup's menu is over everything else: the layout it's in doesn't hold it.
        if k == "Popup" { return false }
        guard container else { return false }
        let inner = k == "Row" || k == "Flow" ? hugs(node) : columnHugs(node, hug)
        return node.children.contains { (k == "Row" && weight($0) > 0) || wants($0, horizontal: true, hug: inner) }
    }

    /// The level the node's file declared.
    static func hugs(_ n: OwlNode) -> Bool { n.level >= 10 }

    /// Since owl 11 a Column in a Row or Flow without width, weight or fill is as wide as its content. [hug] is
    /// whether its parent passes that on: a Row or Flow, or a Column that hugs. A lazy Column fills.
    static func columnHugs(_ n: OwlNode, _ hug: Bool) -> Bool {
        guard hug, n.kind == "Column", n.level >= 11 else { return false }
        return !sized(n) && !n["lazy"].isTrue
    }

    /// What a child is handed as its hug by a parent of [parentKind] that was handed [parentHug] itself.
    static func hugFor(_ child: OwlNode, parentKind: String, parent: OwlNode, parentHug: Bool) -> Bool {
        if parentKind == "Row" || parentKind == "Flow" { return hugs(child) }
        return parentKind == "Column" && columnHugs(parent, parentHug)
    }

    /// Text styles, the launcher's: (size, muted).
    static func style(_ name: String?) -> (Double, Bool) {
        switch name {
        case "huge": return (44, false)
        case "title": return (20, false)
        case "small": return (11, false)
        case "muted": return (13, true)
        case "label": return (11, true)
        default: return (13, false)
        }
    }

    /// huge and title stay on one line in narrow tiles instead of breaking mid-word.
    static func maxLines(_ n: OwlNode) -> Int {
        if let m = n["maxLines"].number, m > 0 { return Int(m) }
        let s = n["style"].string
        return s == "huge" || s == "title" ? 1 : 0
    }

    /// minLines (owl 11): the lines a Text is at least as tall as, never past maxLines.
    static func minLines(_ n: OwlNode) -> Int {
        let max = maxLines(n)
        let m = Int((n["minLines"].number ?? 1).rounded(.down))
        return Swift.max(1, max > 0 ? Swift.min(m, max) : m)
    }

    /// A Column's or Grid's children in the order they're laid out. A lazy one with `reverse` (owl 11) lists
    /// from its end: a Column's turned around, a Grid's rows turned around, the short last row on top with
    /// empty cells (nil) after it.
    static func ordered(_ n: OwlNode) -> [OwlNode?] {
        let c = n.children
        guard n["lazy"].isTrue, n["reverse"].isTrue else { return c }
        if n.kind == "Column" { return c.reversed() }
        guard n.kind == "Grid", !c.isEmpty else { return c }
        let cols = max(1, Int((n["columns"].number ?? 2).rounded()))
        var out = [OwlNode?]()
        var start = (c.count - 1) / cols * cols
        while start >= 0 {
            for i in start..<(start + cols) { out.append(i < c.count ? c[i] : nil) }
            start -= cols
        }
        return out
    }
}

/// How a child sits in its Row, Column, Box or Grid, in points (-1 for "its own size").
struct OwlPlace: Equatable {
    var fillW = false
    var fillH = false
    var prefW: Double = -1
    var prefH: Double = -1
    /// A share of the space left along a Row or Column.
    var weight: Double = 0
    var shown = true

    static let none = OwlPlace()

    init() {}

    /// OwlLayout.place: what [child] asks for inside a [parentKind].
    init(_ child: OwlNode, parentKind: String, hug: Bool, dp: Double) {
        let w = OwlRules.fixedWidth(child), h = OwlRules.fixedHeight(child)
        let weight = OwlRules.weight(child)
        fillW = w < 0 && OwlRules.wants(child, horizontal: true, hug: hug)
        fillH = h < 0 && OwlRules.wants(child, horizontal: false)
        prefW = w >= 0 ? w * dp : -1
        prefH = h >= 0 ? h * dp : -1
        shown = child.shown
        if parentKind == "Row" && weight > 0 { fillW = true; self.weight = weight; if w < 0 { prefW = -1 } }
        if parentKind == "Column" && weight > 0 { fillH = true; self.weight = weight; if h < 0 { prefH = -1 } }
        // What fills the rest of a Column shares it, as weight 1 would.
        if parentKind == "Column" && weight <= 0 && fillH { self.weight = 1 }
        if parentKind == "Grid" && w < 0 { fillW = true }
    }
}

struct OwlPlaceKey: LayoutValueKey {
    static let defaultValue = OwlPlace.none
}

private func finite(_ v: CGFloat?) -> CGFloat? {
    guard let v, v.isFinite else { return nil }
    return v
}

/// Row and Column, laid out as Compose does it: the unweighted children first, in order, each given what is
/// left (a child that fills -- an unsized Text -- takes all of it); then the weighted ones share the rest by
/// weight; then justify and align place them.
struct OwlLinearLayout: Layout {
    var horizontal: Bool
    var gap: CGFloat
    var justify: String
    var align: String?

    struct Sizes {
        var main: [CGFloat]
        var cross: [CGFloat]
    }

    private func place(_ s: LayoutSubview) -> OwlPlace { s[OwlPlaceKey.self] }

    private func ownMain(_ p: OwlPlace) -> CGFloat { horizontal ? p.prefW : p.prefH }
    private func ownCross(_ p: OwlPlace) -> CGFloat { horizontal ? p.prefH : p.prefW }
    private func fillsMain(_ p: OwlPlace) -> Bool { horizontal ? p.fillW : p.fillH }
    private func fillsCross(_ p: OwlPlace) -> Bool { horizontal ? p.fillH : p.fillW }

    /// A child's size along one axis with nothing else known, or with the other axis set.
    private func natural(_ s: LayoutSubview, width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
        s.sizeThatFits(ProposedViewSize(width: width, height: height))
    }

    func sizes(_ subviews: Subviews, room: CGSize) -> Sizes {
        let mainRoom = horizontal ? room.width : room.height
        let crossRoom = horizontal ? room.height : room.width
        let places = subviews.map(place)
        let n = places.filter(\.shown).count
        var left = mainRoom - gap * CGFloat(max(n - 1, 0))
        var main = [CGFloat](repeating: 0, count: subviews.count)
        var cross = [CGFloat](repeating: 0, count: subviews.count)
        var total: Double = 0
        if horizontal {
            // A Row's widths first, then each child's height at its width.
            for (i, s) in subviews.enumerated() where places[i].shown {
                let p = places[i]
                if p.weight > 0 { total += p.weight; continue }
                let own = ownMain(p)
                let size = own >= 0 ? own : fillsMain(p) ? max(left, 0) : min(natural(s).width, max(left, 0))
                main[i] = size
                left -= size
            }
            for i in subviews.indices where places[i].shown && places[i].weight > 0 {
                main[i] = max(left, 0) * places[i].weight / total
            }
            for (i, s) in subviews.enumerated() where places[i].shown {
                let p = places[i]
                let own = ownCross(p)
                cross[i] = own >= 0 ? own : fillsCross(p) ? crossRoom : min(natural(s, width: main[i]).height, crossRoom)
            }
        } else {
            // A Column's widths first, so a Text that wraps knows how tall it is.
            for (i, s) in subviews.enumerated() where places[i].shown {
                let p = places[i]
                let own = ownCross(p)
                cross[i] = own >= 0 ? own : fillsCross(p) ? crossRoom : min(natural(s).width, crossRoom)
            }
            for (i, s) in subviews.enumerated() where places[i].shown {
                let p = places[i]
                if p.weight > 0 { total += p.weight; continue }
                let own = ownMain(p)
                let size = own >= 0 ? own : fillsMain(p) ? max(left, 0) : min(natural(s, width: cross[i]).height, max(left, 0))
                main[i] = size
                left -= size
            }
            for i in subviews.indices where places[i].shown && places[i].weight > 0 {
                main[i] = max(left, 0) * places[i].weight / total
            }
        }
        return Sizes(main: main, cross: cross)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let places = subviews.map(place)
        let n = places.filter(\.shown).count
        let gaps = gap * CGFloat(max(n - 1, 0))
        var sum: CGFloat = 0, maxCross: CGFloat = 0
        let width = finite(proposal.width)
        for (i, s) in subviews.enumerated() where places[i].shown {
            let p = places[i]
            if horizontal {
                if p.weight <= 0 { sum += p.prefW >= 0 ? p.prefW : natural(s).width }
                maxCross = max(maxCross, p.prefH >= 0 ? p.prefH : natural(s).height)
            } else {
                if p.weight <= 0 { sum += p.prefH >= 0 ? p.prefH : natural(s, width: width.map { p.prefW >= 0 ? p.prefW : p.fillW ? $0 : min(natural(s).width, $0) }).height }
                maxCross = max(maxCross, p.prefW >= 0 ? p.prefW : natural(s).width)
            }
        }
        let implicit = horizontal ? CGSize(width: sum + gaps, height: maxCross) : CGSize(width: maxCross, height: sum + gaps)
        return CGSize(width: width ?? implicit.width, height: finite(proposal.height) ?? implicit.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let s = sizes(subviews, room: bounds.size)
        let places = subviews.map(place)
        let room = horizontal ? bounds.width : bounds.height
        let crossRoom = horizontal ? bounds.height : bounds.width
        var n = 0, used: CGFloat = 0, weighted = false
        for i in subviews.indices where places[i].shown {
            n += 1
            used += s.main[i]
            if places[i].weight > 0 { weighted = true }
        }
        // Where each goes along the axis: justify, when nothing is weighted.
        let j = weighted ? "start" : justify
        let spaced = j.hasPrefix("space")
        let free = max(room - used - (spaced ? 0 : gap * CGFloat(max(n - 1, 0))), 0)
        let nf = CGFloat(max(n, 1))
        var at: CGFloat = j == "end" ? free : j == "center" ? free / 2 : j == "spaceAround" ? free / nf / 2 : j == "spaceEvenly" ? free / (nf + 1) : 0
        let step: CGFloat = j == "spaceBetween" ? (n > 1 ? free / CGFloat(n - 1) : 0) : j == "spaceAround" ? free / nf : j == "spaceEvenly" ? free / (nf + 1) : gap
        for (i, sub) in subviews.enumerated() {
            guard places[i].shown else {
                sub.place(at: bounds.origin, proposal: .zero)
                continue
            }
            let size = s.cross[i]
            let crossAt: CGFloat
            if horizontal {
                crossAt = align == "top" || align == "start" ? 0 : align == "bottom" || align == "end" ? crossRoom - size : (crossRoom - size) / 2
            } else {
                crossAt = align == "center" ? (crossRoom - size) / 2 : align == "end" ? crossRoom - size : 0
            }
            let origin = horizontal ? CGPoint(x: bounds.minX + at, y: bounds.minY + crossAt) : CGPoint(x: bounds.minX + crossAt, y: bounds.minY + at)
            let w = horizontal ? s.main[i] : size, h = horizontal ? size : s.main[i]
            sub.place(at: origin, anchor: .topLeading, proposal: ProposedViewSize(width: w, height: h))
            at += s.main[i] + step
        }
    }
}

/// A Box: each child at its align, as big as it is or as the Box when it fills.
struct OwlBoxLayout: Layout {
    var align: String

    private func offset(_ horizontal: Bool, _ room: CGFloat) -> CGFloat {
        let a = align
        if horizontal {
            if a == "end" || a.hasSuffix("End") { return room }
            if a == "start" || a.hasSuffix("Start") { return 0 }
            return room / 2
        }
        if a.hasPrefix("top") { return 0 }
        if a.hasPrefix("bottom") { return room }
        return room / 2
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var w: CGFloat = 0, h: CGFloat = 0
        for s in subviews where s[OwlPlaceKey.self].shown {
            let n = s.sizeThatFits(.unspecified)
            let p = s[OwlPlaceKey.self]
            w = max(w, p.prefW >= 0 ? p.prefW : n.width)
            h = max(h, p.prefH >= 0 ? p.prefH : n.height)
        }
        return CGSize(width: finite(proposal.width) ?? w, height: finite(proposal.height) ?? h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for s in subviews {
            let p = s[OwlPlaceKey.self]
            guard p.shown else {
                s.place(at: bounds.origin, proposal: .zero)
                continue
            }
            let w = p.prefW >= 0 ? p.prefW : p.fillW ? bounds.width : min(s.sizeThatFits(.unspecified).width, bounds.width)
            let h = p.prefH >= 0 ? p.prefH : p.fillH ? bounds.height : min(s.sizeThatFits(ProposedViewSize(width: w, height: nil)).height, bounds.height)
            s.place(at: CGPoint(x: bounds.minX + offset(true, bounds.width - w), y: bounds.minY + offset(false, bounds.height - h)),
                    anchor: .topLeading, proposal: ProposedViewSize(width: w, height: h))
        }
    }
}

/// A Grid: `columns` of equal width, each row as tall as its tallest child.
struct OwlGridLayout: Layout {
    var columns: Int
    var gap: CGFloat

    private func rows(_ subviews: Subviews, cell: CGFloat) -> [CGFloat] {
        var heights = [CGFloat]()
        for (i, s) in subviews.enumerated() {
            let p = s[OwlPlaceKey.self]
            let h = !p.shown ? 0 : p.prefH >= 0 ? p.prefH : s.sizeThatFits(ProposedViewSize(width: p.prefW >= 0 ? p.prefW : cell, height: nil)).height
            if i % columns == 0 { heights.append(h) } else { heights[heights.count - 1] = max(heights[heights.count - 1], h) }
        }
        return heights
    }

    private func cellWidth(_ width: CGFloat) -> CGFloat {
        max(0, (width - gap * CGFloat(columns - 1)) / CGFloat(columns))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width: CGFloat
        if let w = finite(proposal.width) { width = w } else {
            let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            width = widest * CGFloat(columns) + gap * CGFloat(columns - 1)
        }
        let r = rows(subviews, cell: cellWidth(width))
        let height = r.reduce(0, +) + gap * CGFloat(max(r.count - 1, 0))
        return CGSize(width: width, height: finite(proposal.height) ?? height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cell = cellWidth(bounds.width)
        let r = rows(subviews, cell: cell)
        var y = bounds.minY
        for (i, s) in subviews.enumerated() {
            let row = i / columns, col = i % columns
            if col == 0 && row > 0 { y += r[row - 1] + gap }
            let p = s[OwlPlaceKey.self]
            let w = p.prefW >= 0 ? p.prefW : cell
            s.place(at: CGPoint(x: bounds.minX + CGFloat(col) * (cell + gap), y: y), anchor: .topLeading,
                    proposal: ProposedViewSize(width: p.shown ? w : 0, height: p.shown ? (p.prefH >= 0 ? p.prefH : r[row]) : 0))
        }
    }
}

/// A Flow, and a Row with `wrap: true`: children at their own size, onto the next line when one is full.
struct OwlFlowLayout: Layout {
    var gap: CGFloat

    private func lines(_ subviews: Subviews, width: CGFloat) -> [(CGPoint, CGSize)] {
        var out = [(CGPoint, CGSize)]()
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0
        for s in subviews {
            let p = s[OwlPlaceKey.self]
            guard p.shown else {
                out.append((.zero, .zero))
                continue
            }
            let n = s.sizeThatFits(.unspecified)
            let w = min(p.prefW >= 0 ? p.prefW : n.width, width)
            let h = p.prefH >= 0 ? p.prefH : s.sizeThatFits(ProposedViewSize(width: w, height: nil)).height
            if x > 0 && x + w > width {
                x = 0
                y += line + gap
                line = 0
            }
            out.append((CGPoint(x: x, y: y), CGSize(width: w, height: h)))
            x += w + gap
            line = max(line, h)
        }
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = finite(proposal.width) ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + gap }
        let l = lines(subviews, width: width)
        let height = l.map { $0.0.y + $0.1.height }.max() ?? 0
        return CGSize(width: width, height: finite(proposal.height) ?? height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (s, (at, size)) in zip(subviews, lines(subviews, width: bounds.width)) {
            s.place(at: CGPoint(x: bounds.minX + at.x, y: bounds.minY + at.y), anchor: .topLeading, proposal: ProposedViewSize(size))
        }
    }
}

/// Canvas, Shader and Terminal: whatever they're given, and nothing of their own.
struct OwlFillLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: finite(proposal.width) ?? 0, height: finite(proposal.height) ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for s in subviews { s.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size)) }
    }
}
