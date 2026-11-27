import SwiftUI

/// A font weight from fontWeight (1 to 1000) or bold.
func owlWeight(_ w: OwlValue, bold: Bool) -> Font.Weight {
    guard let n = w.number else { return bold ? .bold : .regular }
    switch n {
    case ..<150: return .ultraLight
    case ..<250: return .thin
    case ..<350: return .light
    case ..<450: return .regular
    case ..<550: return .medium
    case ..<650: return .semibold
    case ..<750: return .bold
    case ..<850: return .heavy
    default: return .black
    }
}

func owlFont(_ family: String, size: CGFloat) -> Font {
    family.isEmpty ? .system(size: size) : .custom(family, fixedSize: size)
}

struct OwlText: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let dp = widget.dp
        let (styleSize, muted) = OwlRules.style(node["style"].string)
        let size = max(1, min(1000, node["fontSize"].number ?? styleSize)) * dp
        let color = node["color"].color ?? widget.theme.color(muted ? "muted" : "foreground")
        let max = OwlRules.maxLines(node)
        let align = node["align"].string
        // The launcher spaces lines 1.17 em apart, Android's monospace: a line of this one is kept to that.
        let line = size * 1.17
        text(size: size)
            .foregroundStyle(color)
            .animation(OwlAnimation.of(node.a["color"]), value: color)
            .lineLimit(max > 0 ? max : nil)
            .truncationMode(.tail)
            .multilineTextAlignment(align == "center" ? .center : align == "end" ? .trailing : .leading)
            .fixedSize(horizontal: max == 1 && node["width"].isNull, vertical: false)
            .frame(minHeight: max == 1 ? line : CGFloat(OwlRules.minLines(node)) * line, maxHeight: max == 1 ? line : nil)
            .frame(maxWidth: .infinity, alignment: align == "center" ? .top : align == "end" ? .topTrailing : .topLeading)
    }

    private func text(size: CGFloat) -> Text {
        let dp = widget.dp
        let family = widget.family(node["font"].string)
        var base = Text("")
        // spans (owl 10): each piece styled on its own, the spaces at its ends kept.
        if let spans = node["spans"].list {
            for piece in spans {
                var t = Text(piece["text"].string ?? "")
                let pSize = piece["fontSize"].number.map { max(1, min(1000, $0)) * dp } ?? size
                let pFamily = piece["font"].string.map { widget.family($0) } ?? family
                t = t.font(owlFont(pFamily, size: pSize))
                    .fontWeight(owlWeight(piece["fontWeight"].isNull ? node["fontWeight"] : piece["fontWeight"],
                                          bold: piece["bold"].bool ?? node["bold"].isTrue))
                if piece["italic"].bool ?? node["italic"].isTrue { t = t.italic() }
                if let c = piece["color"].color { t = t.foregroundColor(c) }
                if let ls = piece["letterSpacing"].number ?? node["letterSpacing"].number { t = t.kerning(max(-1000, min(1000, ls)) * dp) }
                base = base + t
            }
            return base
        }
        var t = Text(node["text"].string ?? "…").font(owlFont(family, size: size))
            .fontWeight(owlWeight(node["fontWeight"], bold: node["bold"].isTrue))
        if node["italic"].isTrue { t = t.italic() }
        if let ls = node["letterSpacing"].number { t = t.kerning(max(-1000, min(1000, ls)) * dp) }
        return t
    }
}

struct OwlButton: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let dp = widget.dp
        let color = node["color"].color ?? widget.theme.color("accent")
        Text(node["text"].string ?? "…")
            .font(owlFont(widget.family("mono"), size: 13 * dp))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10 * dp)
            .padding(.vertical, 6 * dp)
            // As wide as it's given, with weight: or fill:, its label in the middle.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The launcher's corners follow its style, and Omarchy's is square.
            .overlay(RoundedRectangle(cornerRadius: (node["radius"].number ?? 0) * dp).strokeBorder(color, lineWidth: max(1, dp)))
    }
}

/// value/max, 0 to 1. A Ring's max is 1 unless it says, a Progress's 100.
private func fraction(_ node: OwlNode) -> Double {
    let max = Swift.max(node["max"].number ?? (node.kind == "Ring" ? 1 : 100), 1e-9)
    return Swift.max(0, Swift.min(1, (node["value"].number ?? 0) / max))
}

struct OwlProgress: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let f = fraction(node)
        Rectangle()
            .fill(node["track"].color ?? widget.theme.color("surface"))
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().fill(node["color"].color ?? widget.theme.color("accent")).frame(width: geo.size.width * f)
                }
            }
            .animation(OwlAnimation.of(node.a["value"]), value: f)
            .frame(idealWidth: 60 * widget.dp, idealHeight: 8 * widget.dp)
    }
}

/// An arc from `start` degrees (0 at the top, clockwise) through `sweep`, as far as [fraction] of it.
struct OwlArc: Shape {
    var start: Double
    var sweep: Double
    var fraction: Double
    var thickness: CGFloat

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2 - thickness / 2
        let a0 = Angle.degrees(start - 90)
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: max(r, 0), startAngle: a0,
                 endAngle: a0 + .degrees(sweep * fraction), clockwise: false)
        return p
    }
}

struct OwlRing: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let t = (node["thickness"].number ?? 6) * widget.dp
        let start = node["start"].number ?? 0, sweep = node["sweep"].number ?? 360
        let f = fraction(node)
        let style = StrokeStyle(lineWidth: t, lineCap: .round)
        ZStack {
            OwlArc(start: start, sweep: sweep, fraction: 1, thickness: t).stroke(node["track"].color ?? widget.theme.color("surface"), style: style)
            OwlArc(start: start, sweep: sweep, fraction: f, thickness: t).stroke(node["color"].color ?? widget.theme.color("accent"), style: style)
                .opacity(f > 0 ? 1 : 0)
        }
        .animation(OwlAnimation.of(node.a["value"]), value: f)
        .frame(idealWidth: 64 * widget.dp, idealHeight: 64 * widget.dp)
    }
}

struct OwlSparkline: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let values = (node["values"].list ?? []).map(\.number)
        let line = node["color"].color ?? widget.theme.color("accent")
        let thickness = (node["thickness"].number ?? 2) * widget.dp
        let area = node["area"]
        Canvas { ctx, size in
            let lo = node["min"].number ?? 0
            var hi = node["max"].number ?? .nan
            if hi.isNaN {
                // Auto-scaled lines get headroom so the peak is not glued to the top.
                let peak = values.compactMap { $0 }.max() ?? -.infinity
                hi = Swift.max(lo + (peak - lo) * 1.15, lo + 1)
            }
            if !hi.isFinite || hi <= lo { hi = lo + 1 }
            let n = values.count
            let pts: [CGPoint] = values.enumerated().compactMap { i, v in
                v.map { CGPoint(x: n > 1 ? Double(i) / Double(n - 1) * size.width : size.width / 2, y: size.height - ($0 - lo) / (hi - lo) * size.height) }
            }
            guard pts.count >= 2 else { return }
            var path = Path()
            path.addLines(pts)
            if area.isTrue || area.color != nil {
                var fill = path
                fill.addLine(to: CGPoint(x: pts.last!.x, y: size.height))
                fill.addLine(to: CGPoint(x: pts[0].x, y: size.height))
                fill.closeSubpath()
                ctx.fill(fill, with: .color(area.color ?? line.opacity(0.2)))
            }
            ctx.stroke(path, with: .color(line), style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
        }
        .frame(idealWidth: 80 * widget.dp, idealHeight: 48 * widget.dp)
    }
}

struct OwlImage: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let src = node["src"].string ?? ""
        if let img = OwlImages.shared.image(src, home: widget.host.home) {
            let fit = node["fit"].string
            let tint = node["tint"].color
            let image = Image(owl: img).resizable().renderingMode(tint == nil ? .original : .template).interpolation(.high)
            Group {
                if fit == "fill" {
                    image
                } else if fit == "cover" {
                    // Taller as it gets wider, at the picture's own aspect, cropped to what it's given.
                    Color.clear.aspectRatio(img.size, contentMode: .fit).overlay(image.aspectRatio(contentMode: .fill)).clipped()
                } else {
                    image.aspectRatio(contentMode: .fit)
                }
            }
            .foregroundStyle(tint ?? .white)
            .accessibilityLabel(node["label"].string ?? "")
        } else {
            Color.clear.frame(width: 0, height: 0)
        }
    }
}

struct OwlSlider: View {
    let node: OwlNode
    let widget: OwlWidget
    @State private var dragged: Double?

    var body: some View {
        let dp = widget.dp
        let lo = node["min"].number ?? 0
        let hi = max(node["max"].number ?? 100, lo + 1e-9)
        let value = dragged ?? node["value"].number ?? lo
        let f = max(0, min(1, (value - lo) / (hi - lo)))
        let color = node["color"].color ?? widget.theme.color("accent")
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(node["track"].color ?? widget.theme.color("foreground").opacity(0.15)).frame(height: 4 * dp)
                Capsule().fill(color).frame(width: w * f, height: 4 * dp)
                Circle().fill(color).frame(width: 16 * dp, height: 16 * dp).offset(x: w * f - 8 * dp)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = at(g.location.x, width: w, lo: lo, hi: hi)
                dragged = v
                if node["live"].isTrue { widget.handle(node.handlers["onChange"], [v]) }
            }.onEnded { g in
                widget.handle(node.handlers["onChange"], [at(g.location.x, width: w, lo: lo, hi: hi)])
                dragged = nil
            })
        }
        .frame(idealWidth: 120 * dp, idealHeight: 28 * dp)
    }

    private func at(_ x: CGFloat, width: CGFloat, lo: Double, hi: Double) -> Double {
        var v = lo + max(0, min(1, x / max(width, 1))) * (hi - lo)
        if let step = node["step"].number, step > 0 { v = lo + ((v - lo) / step).rounded() * step }
        return max(lo, min(hi, v))
    }
}

struct OwlInput: View {
    let node: OwlNode
    let widget: OwlWidget
    @State private var text = ""
    @FocusState private var focused: Bool
    @Environment(\.owlStatic) private var still

    private var given: String {
        let t = node["text"].string ?? ""
        return t == "…" ? "" : t
    }

    var body: some View {
        let dp = widget.dp
        let size = (node["fontSize"].number ?? 14) * dp
        let prompt = Text(node["placeholder"].string ?? "").foregroundColor(widget.theme.color("muted"))
        Group {
            // ImageRenderer draws no text field: a picture shows what it holds, or its placeholder.
            if still {
                (given.isEmpty ? prompt : Text(node["password"].isTrue ? String(repeating: "•", count: given.count) : given))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            // password: true (owl 12): dots for what's typed, and no suggestions that would learn it.
            } else if node["password"].isTrue {
                SecureField("", text: $text, prompt: prompt)
            } else {
                TextField("", text: $text, prompt: prompt)
            }
        }
        .textFieldStyle(.plain)
        .font(owlFont(widget.family("sans"), size: size))
        .foregroundStyle(node["color"].color ?? widget.theme.color("foreground"))
        .focused($focused)
        .padding(6 * dp)
        .overlay {
            // underline: false (owl 10) leaves the line out, for a field in a frame of its own.
            if !(node["underline"].bool == false) {
                RoundedRectangle(cornerRadius: 6 * dp).strokeBorder(widget.theme.color("foreground").opacity(focused ? 0.5 : 0.2), lineWidth: max(1, dp))
            }
        }
        .frame(idealWidth: 120 * dp)
        .onAppear {
            text = given
            if node["focus"].isTrue { focused = true }
        }
        .onChange(of: given) { _, new in if new != text { text = new } }
        .onChange(of: text) { _, new in if new != given { widget.handle(node.handlers["onChange"], [new]) } }
        .onChange(of: focused) { _, f in widget.host.fieldFocused(f) }
        .onSubmit {
            widget.handle(node.handlers["onSubmit"], [text])
            if node["clear"].isTrue { text = "" }
        }
    }
}

/// Terminal { }: a desktop has real terminals, so the tile shows the command and opens it in one.
struct OwlTerminal: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let dp = widget.dp
        let command = node["command"].string ?? ""
        ZStack(alignment: .topLeading) {
            Rectangle().fill(widget.theme.color("dark_background"))
            Text("$ " + (command.isEmpty ? "bash" : command))
                .font(owlFont(widget.family("mono"), size: (node["fontSize"].number ?? 11) * dp))
                .foregroundStyle(widget.theme.color("muted"))
                .padding(6 * dp)
        }
        .contentShape(Rectangle())
        .onTapGesture { widget.host.openTerminal(command) }
    }
}
