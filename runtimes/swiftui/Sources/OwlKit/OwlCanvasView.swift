import SwiftUI

/// An OWL Canvas: asks the instance for this frame's display list and paints it, as OwlLayout.js paints one
/// onto a Context2D. The drawing calls are in dp, so the context is scaled once.
///
/// A widget that reads `time` draws again every frame while its board is up (OwlWidget.frameCount); any other
/// only when the node, the size or the theme changes.
struct OwlCanvasView: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let _ = widget.frameCount
        let _ = OwlImages.shared.loaded
        let _ = widget.fontsLoaded
        Canvas { ctx, size in
            MainActor.assumeIsolated {
                guard let id = node.draw, size.width > 0, size.height > 0 else { return }
                let dp = widget.dp
                var c = ctx
                c.scaleBy(x: dp, y: dp)
                let ops = widget.draw(id, width: size.width / dp, height: size.height / dp)
                OwlPainter(widget: widget).paint(&c, ops)
            }
        }
    }
}

@MainActor
struct OwlPainter {
    let widget: OwlWidget

    func paint(_ ctx: inout GraphicsContext, _ ops: [OwlDrawOp]) {
        for op in ops { paintOp(&ctx, op) }
    }

    private func shading(_ v: OwlValue) -> GraphicsContext.Shading? {
        if let c = v.color { return .color(c) }
        guard let g = v.gradient else { return nil }
        if g.radial {
            return .radialGradient(g.stops, center: CGPoint(x: g.coord(0), y: g.coord(1)), startRadius: 0, endRadius: max(g.coord(2), 0.001))
        }
        return .linearGradient(g.stops, startPoint: CGPoint(x: g.coord(0), y: g.coord(1)), endPoint: CGPoint(x: g.coord(2), y: g.coord(3)))
    }

    private var foreground: GraphicsContext.Shading { .color(widget.theme.color("foreground")) }

    /// Fill and stroke as the call says; with neither, its color fills -- or strokes, for a line.
    private func shape(_ ctx: inout GraphicsContext, _ op: OwlDrawOp, _ path: Path, strokeByDefault: Bool = false) {
        var fill = shading(op["fill"])
        var stroke = shading(op["stroke"])
        if fill == nil && stroke == nil {
            if strokeByDefault { stroke = shading(op["color"]) ?? foreground } else { fill = shading(op["color"]) ?? foreground }
        }
        if let fill { ctx.fill(path, with: fill) }
        if let stroke {
            let cap = op["cap"].string
            ctx.stroke(path, with: stroke, style: StrokeStyle(lineWidth: op["width"].number ?? 1,
                                                              lineCap: cap == "round" ? .round : cap == "square" ? .square : .butt,
                                                              lineJoin: cap == "round" ? .round : .miter))
        }
    }

    private func roundRect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> Path {
        let rect = CGRect(x: w < 0 ? x + w : x, y: h < 0 ? y + h : y, width: abs(w), height: abs(h))
        let r = max(0, min(r, rect.width / 2, rect.height / 2))
        return r <= 0 ? Path(rect) : Path(roundedRect: rect, cornerRadius: r)
    }

    private func paintOp(_ ctx: inout GraphicsContext, _ op: OwlDrawOp) {
        let n = op.arg
        switch op.op {
        case "rect":
            shape(&ctx, op, roundRect(n(0), n(1), n(2), n(3), op["radius"].number ?? 0))
        case "circle":
            let r = max(n(2), 0)
            shape(&ctx, op, Path(ellipseIn: CGRect(x: n(0) - r, y: n(1) - r, width: 2 * r, height: 2 * r)))
        case "arc":
            // 0 degrees at the top, clockwise; filled, it's a pie slice.
            let filled = !op["fill"].isNull || op["stroke"].isNull
            var p = Path()
            let center = CGPoint(x: n(0), y: n(1))
            if filled { p.move(to: center) }
            p.addArc(center: center, radius: max(n(2), 0), startAngle: .degrees(n(3) - 90), endAngle: .degrees(n(3) + n(4) - 90), clockwise: n(4) < 0)
            if filled && op["stroke"].isNull { p.closeSubpath() }
            shape(&ctx, op, p)
        case "line":
            var p = Path()
            p.move(to: CGPoint(x: n(0), y: n(1)))
            p.addLine(to: CGPoint(x: n(2), y: n(3)))
            var line = op
            line.named = ["stroke": op["stroke"].isNull ? (op["color"].isNull ? op["fill"] : op["color"]) : op["stroke"],
                          "width": op["width"], "cap": op["cap"]]
            shape(&ctx, line, p, strokeByDefault: true)
        case "path":
            let pts = (op["points"].list ?? []).map { CGPoint(x: $0[0].number ?? 0, y: $0[1].number ?? 0) }
            guard let first = pts.first else { return }
            var p = Path()
            p.move(to: first)
            for q in pts.dropFirst() { p.addLine(to: q) }
            if op["closed"].isTrue { p.closeSubpath() }
            shape(&ctx, op, p)
        case "text":
            text(&ctx, op)
        case "image":
            guard let src = op["src"].string, let img = OwlImages.shared.image(src, home: widget.host.home) else { return }
            ctx.draw(Image(owl: img).resizable(), in: CGRect(x: n(1), y: n(2), width: n(3), height: n(4)))
        case "translate":
            group(&ctx, op) { $0.translateBy(x: n(0), y: n(1)) }
        case "rotate":
            group(&ctx, op) {
                $0.translateBy(x: n(1), y: n(2))
                $0.rotate(by: .degrees(n(0)))
                $0.translateBy(x: -n(1), y: -n(2))
            }
        case "scale":
            group(&ctx, op) {
                let sx = n(0), sy = op.args.count > 1 ? n(1) : sx
                $0.translateBy(x: n(2), y: n(3))
                $0.scaleBy(x: sx, y: sy)
                $0.translateBy(x: -n(2), y: -n(3))
            }
        case "clip":
            group(&ctx, op) { $0.clip(to: Path(CGRect(x: n(0), y: n(1), width: n(2), height: n(3)))) }
        case "layer":
            group(&ctx, op) { $0.opacity *= max(0, min(1, op.args.first.flatMap { $0 } ?? 1)) }
        default:
            break
        }
    }

    private func group(_ ctx: inout GraphicsContext, _ op: OwlDrawOp, _ setup: (inout GraphicsContext) -> Void) {
        var inner = ctx
        setup(&inner)
        paint(&inner, op.ops)
    }

    /// text(...): left, centred or right of x, its middle on y; since owl 10 a font, weight and slant of its own,
    /// and its text in spans, each styled on its own.
    private func text(_ ctx: inout GraphicsContext, _ op: OwlDrawOp) {
        let size = op["size"].number ?? 12
        let base = op["color"].color ?? op["fill"].color ?? widget.theme.color("foreground")
        let pieces: [OwlValue] = op["spans"].list ?? [.object(["text": op["text"]])]
        var resolved = [GraphicsContext.ResolvedText]()
        var total: CGFloat = 0
        for piece in pieces {
            let name = piece["font"].string ?? op["font"].string
            // A Canvas draws in the sans font unless it says.
            let family = name == nil ? widget.host.sansFamily : widget.family(name)
            let weight = owlWeight(piece["fontWeight"].isNull ? op["fontWeight"] : piece["fontWeight"], bold: piece["bold"].bool ?? op["bold"].isTrue)
            var t = Text(piece["text"].string ?? "").font(owlFont(family, size: piece["fontSize"].number ?? size)).fontWeight(weight)
            if piece["italic"].bool ?? op["italic"].isTrue { t = t.italic() }
            if let ls = piece["letterSpacing"].number ?? op["letterSpacing"].number { t = t.kerning(ls) }
            t = t.foregroundColor(piece["color"].color ?? base)
            let r = ctx.resolve(t)
            resolved.append(r)
            total += r.measure(in: CGSize(width: CGFloat.infinity, height: .infinity)).width
        }
        let align = op["align"].string
        var x = op.arg(1) - (align == "center" ? total / 2 : align == "end" ? total : 0)
        for r in resolved {
            ctx.draw(r, at: CGPoint(x: x, y: op.arg(2)), anchor: .leading)
            x += r.measure(in: CGSize(width: CGFloat.infinity, height: .infinity)).width
        }
    }
}
