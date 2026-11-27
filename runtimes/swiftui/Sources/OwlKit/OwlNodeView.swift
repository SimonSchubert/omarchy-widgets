import SwiftUI

/// One node of an OWL widget, drawn from the tree Owl.js renders. Children are identified by their place in
/// the list, so a source that updates a widget's text redraws that text and rebuilds nothing.
public struct OwlNodeView: View {
    let node: OwlNode
    let widget: OwlWidget
    /// Whether the node it's in hands it a hug: a Row's, or a hugging Column's.
    var hugged = false

    public init(node: OwlNode, widget: OwlWidget) {
        self.node = node
        self.widget = widget
    }

    init(node: OwlNode, widget: OwlWidget, hugged: Bool) {
        self.node = node
        self.widget = widget
        self.hugged = hugged
    }

    @Environment(\.owlStatic) private var still
    @State private var dragLast = CGSize.zero
    @State private var dragging = false
    @State private var pressed = false
    @State private var repeatTask: Task<Void, Never>?

    var dp: CGFloat { widget.dp }
    var p: (String) -> OwlValue { { node[$0] } }
    func h(_ name: String) -> Int? { node.handlers[name] }

    public var body: some View {
        if !node.shown {
            Color.clear.frame(width: 0, height: 0)
        } else if node.kind == "Popup" {
            OwlPopup(node: node, widget: widget)
        } else {
            decorated
        }
    }

    private var pad: EdgeInsets {
        let (l, t, r, b) = OwlRules.padding(node["padding"])
        return EdgeInsets(top: t * dp, leading: l * dp, bottom: b * dp, trailing: r * dp)
    }

    private var radius: CGFloat { (node["radius"].number ?? 0) * dp }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

    private var fixedW: CGFloat? { let w = OwlRules.fixedWidth(node); return w >= 0 ? w * dp : nil }
    private var fixedH: CGFloat? { let h = OwlRules.fixedHeight(node); return h >= 0 ? h * dp : nil }

    @ViewBuilder private var decorated: some View {
        let offset = node["offset"].list.map { CGSize(width: ($0.first?.number ?? 0) * dp, height: ($0.count > 1 ? $0[1].number ?? 0 : 0) * dp) } ?? .zero
        let opacity = node["opacity"].number ?? 1
        let rotation = node["rotation"].number ?? 0
        let scale = node["scale"].number ?? 1
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(pad)
            .frame(width: fixedW, height: fixedH)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background { background }
            .overlay { border }
            .modifier(OwlClip(on: node["clip"].isTrue, shape: shape))
            .contentShape(Rectangle())
            .modifier(OwlGestures(node: node, widget: widget, dragLast: $dragLast, dragging: $dragging, pressed: $pressed, repeatTask: $repeatTask))
            .opacity(opacity)
            .animation(OwlAnimation.of(node.a["opacity"]), value: opacity)
            .scaleEffect(scale)
            .animation(OwlAnimation.of(node.a["scale"]), value: scale)
            .rotationEffect(.degrees(rotation))
            .animation(OwlAnimation.of(node.a["rotation"]), value: rotation)
            .offset(offset)
            // animate offset (owl 13): while the node's own onDrag has the finger the offset follows it as it is;
            // let go, it eases to where onDragEnd puts it.
            .animation(dragging ? nil : OwlAnimation.of(node.a["offset"]), value: offset)
    }

    // ------------------------------------------------------------ decoration

    @ViewBuilder private var background: some View {
        let bg = node["background"]
        let animated = node.a["background"] != nil
        ZStack {
            // frost (owl 10) blurs what's behind the node: here, the window's own content.
            if (node["frost"].number ?? 0) > 0 || node["frost"].isTrue {
                shape.fill(.ultraThinMaterial)
            }
            if let g = bg.gradient, node.level >= 10, !animated {
                OwlGradientFill(gradient: g, shape: shape)
            } else if let c = bg.color ?? bg.gradient?.colors.first ?? nil {
                shape.fill(c).animation(OwlAnimation.of(node.a["background"]), value: bg)
            }
        }
    }

    @ViewBuilder private var border: some View {
        let width = (node["border"].number ?? 0) * dp
        if width > 0 {
            shape.strokeBorder(node["borderColor"].color ?? widget.theme.color("border"), lineWidth: width)
        }
    }

    // --------------------------------------------------------------- content

    @ViewBuilder private var content: some View {
        switch node.kind {
        case "Column":
            let linear = OwlLinear(node: node, widget: widget, horizontal: false, hugged: hugged)
            if (node["scroll"].isTrue || node["lazy"].isTrue) && !still {
                // A lazy Column scrolls (owl 11); this runtime builds all of it, as the Quickshell one does. Listed
                // from its end, it starts at the bottom.
                ScrollView(.vertical) { linear }
                    .defaultScrollAnchor(node["lazy"].isTrue && node["reverse"].isTrue ? .bottom : .top)
                    .scrollIndicators(.never)
            } else if node["scroll"].isTrue || node["lazy"].isTrue {
                // Drawn still: as tall as it is, showing its start, or its end when it's listed from there.
                linear.fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: .infinity, alignment: node["lazy"].isTrue && node["reverse"].isTrue ? .bottom : .top)
                    .clipped()
            } else {
                linear
            }
        case "Row":
            if node["wrap"].isTrue { OwlFlow(node: node, widget: widget) } else { OwlLinear(node: node, widget: widget, horizontal: true, hugged: hugged) }
        case "Flow": OwlFlow(node: node, widget: widget)
        case "Box": OwlBox(node: node, widget: widget)
        case "Grid":
            if node["lazy"].isTrue && !still {
                ScrollView(.vertical) { OwlGrid(node: node, widget: widget) }
                    .defaultScrollAnchor(node["reverse"].isTrue ? .bottom : .top)
                    .scrollIndicators(.never)
            } else if node["lazy"].isTrue {
                OwlGrid(node: node, widget: widget).fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: .infinity, alignment: node["reverse"].isTrue ? .bottom : .top)
                    .clipped()
            } else {
                OwlGrid(node: node, widget: widget)
            }
        case "Text": OwlText(node: node, widget: widget)
        case "Button": OwlButton(node: node, widget: widget)
        case "Progress": OwlProgress(node: node, widget: widget)
        case "Ring": OwlRing(node: node, widget: widget)
        case "Sparkline": OwlSparkline(node: node, widget: widget)
        case "Image": OwlImage(node: node, widget: widget)
        case "Canvas": OwlFillLayout { OwlCanvasView(node: node, widget: widget) }
        // AGSL doesn't run here; the language allows for this, as older Android phones show `fallback` too.
        case "Shader": OwlFillLayout { Rectangle().fill(node["fallback"].color ?? widget.theme.color("surface")) }
        case "Terminal": OwlFillLayout { OwlTerminal(node: node, widget: widget) }
        case "Slider": OwlSlider(node: node, widget: widget)
        case "Input": OwlInput(node: node, widget: widget)
        // A Spacer, and anything this runtime doesn't draw, still takes its place in the layout.
        default: Color.clear.frame(width: 0, height: 0)
        }
    }
}

// ----------------------------------------------------------------- containers

private struct OwlStaticKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Drawn for a picture rather than a window: ImageRenderer draws no ScrollView, so a scrolling Column is a
    /// plain one, clipped, showing its start.
    public var owlStatic: Bool {
        get { self[OwlStaticKey.self] }
        set { self[OwlStaticKey.self] = newValue }
    }
}

/// A child in its parent's layout, carrying how it's placed.
struct OwlChild: View {
    let node: OwlNode
    let widget: OwlWidget
    let place: OwlPlace
    var hugged = false

    var body: some View {
        OwlNodeView(node: node, widget: widget, hugged: hugged).layoutValue(key: OwlPlaceKey.self, value: place)
    }
}

struct OwlLinear: View {
    let node: OwlNode
    let widget: OwlWidget
    let horizontal: Bool
    let hugged: Bool

    var body: some View {
        let kind = horizontal ? "Row" : "Column"
        let kids = OwlRules.ordered(node).compactMap { $0 }
        OwlLinearLayout(horizontal: horizontal, gap: (node["gap"].number ?? (horizontal ? 8 : 4)) * widget.dp,
                        justify: node["justify"].string ?? "start", align: node["align"].string) {
            ForEach(kids.indices, id: \.self) { i in
                let c = kids[i]
                let hug = OwlRules.hugFor(c, parentKind: kind, parent: node, parentHug: hugged)
                OwlChild(node: c, widget: widget, place: OwlPlace(c, parentKind: kind, hug: hug, dp: widget.dp), hugged: hug)
            }
        }
    }
}

struct OwlBox: View {
    let node: OwlNode
    let widget: OwlWidget

    private func place(_ c: OwlNode) -> OwlPlace {
        var p = OwlPlace(c, parentKind: "Box", hug: false, dp: widget.dp)
        if node.wrapper {
            p.fillW = true
            p.fillH = true
        }
        return p
    }

    var body: some View {
        OwlBoxLayout(align: node["align"].string ?? "topStart") {
            ForEach(node.children.indices, id: \.self) { i in
                let c = node.children[i]
                // A component used with weight: or padding: is wrapped in a Box that only carries those; what it
                // wraps fills it.
                OwlChild(node: c, widget: widget, place: place(c))
            }
        }
    }
}

struct OwlGrid: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let kids = OwlRules.ordered(node)
        OwlGridLayout(columns: max(1, Int((node["columns"].number ?? 2).rounded())), gap: (node["gap"].number ?? 6) * widget.dp) {
            ForEach(kids.indices, id: \.self) { i in
                if let c = kids[i] {
                    OwlChild(node: c, widget: widget, place: OwlPlace(c, parentKind: "Grid", hug: false, dp: widget.dp))
                } else {
                    Color.clear.frame(width: 0, height: 0)
                }
            }
        }
    }
}

struct OwlFlow: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        OwlFlowLayout(gap: (node["gap"].number ?? 8) * widget.dp) {
            ForEach(node.children.indices, id: \.self) { i in
                let c = node.children[i]
                let hug = OwlRules.hugs(c)
                OwlChild(node: c, widget: widget, place: OwlPlace(c, parentKind: "Flow", hug: hug, dp: widget.dp), hugged: hug)
            }
        }
    }
}

/// Popup (owl 10): its children in a menu over everything else, next to where it's written, below it or above
/// with position: above. Framed like the launcher's menus unless it has a background or border. A press
/// outside it or Escape runs onDismiss, which it must have.
struct OwlPopup: View {
    let node: OwlNode
    let widget: OwlWidget

    var body: some View {
        let dp = widget.dp
        let framed = !node["background"].isNull || (node["border"].number ?? 0) > 0
        let align: HorizontalAlignment = node["align"].string == "center" ? .center : node["align"].string == "end" ? .trailing : .leading
        Color.clear
            .frame(width: 0, height: 0)
            .popover(isPresented: Binding(get: { true }, set: { if !$0 { widget.handle(node.handlers["onDismiss"]) } }),
                     arrowEdge: node["position"].string == "above" ? .top : .bottom) {
                VStack(alignment: align, spacing: (node["gap"].number ?? 4) * dp) {
                    ForEach(node.children.indices, id: \.self) { i in
                        OwlNodeView(node: node.children[i], widget: widget, hugged: true).fixedSize()
                    }
                }
                .padding(framed ? OwlRules.padding(node["padding"]).0 * dp : 4 * dp)
                .background(framed ? (node["background"].color ?? .clear) : widget.theme.color("background"))
                .overlay {
                    if !framed { Rectangle().strokeBorder(widget.theme.color("accent"), lineWidth: 2 * dp) }
                    else if (node["border"].number ?? 0) > 0 {
                        Rectangle().strokeBorder(node["borderColor"].color ?? widget.theme.color("border"), lineWidth: (node["border"].number ?? 0) * dp)
                    }
                }
                .onKeyPress(.escape) {
                    widget.handle(node.handlers["onDismiss"])
                    return .handled
                }
            }
    }
}

// --------------------------------------------------------------------- input

/// onTap, onLongPress, onDrag and onDragEnd, onPress and onRelease with repeats. A tap lands on the innermost
/// node that wants it, as SwiftUI gives a child's gesture the first say.
struct OwlGestures: ViewModifier {
    let node: OwlNode
    let widget: OwlWidget
    @Binding var dragLast: CGSize
    @Binding var dragging: Bool
    @Binding var pressed: Bool
    @Binding var repeatTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        let dp = widget.dp
        let tap = node.handlers["onTap"], long = node.handlers["onLongPress"]
        let drag = node.handlers["onDrag"], dragEnd = node.handlers["onDragEnd"]
        let press = node.handlers["onPress"], release = node.handlers["onRelease"]
        // drag: horizontal or vertical (owl 13) takes moves along it alone.
        let axis = node["drag"].string
        let xs: CGFloat = axis == "vertical" ? 0 : 1, ys: CGFloat = axis == "horizontal" ? 0 : 1
        content
            .gesture(tap == nil ? nil : SpatialTapGesture().onEnded { v in
                widget.handle(tap, [v.location.x / dp, v.location.y / dp])
            })
            .simultaneousGesture(long == nil ? nil : LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                widget.handle(long, [0, 0])
            })
            .gesture(drag == nil ? nil : DragGesture(minimumDistance: 3).onChanged { v in
                if !dragging {
                    dragging = true
                    dragLast = .zero
                }
                let dx = (v.translation.width - dragLast.width) * xs, dy = (v.translation.height - dragLast.height) * ys
                dragLast = v.translation
                widget.handle(drag, [dx / dp, dy / dp, v.location.x / dp, v.location.y / dp])
            }.onEnded { v in
                dragging = false
                // How fast the finger was going as it let go, in dp a second.
                widget.handle(dragEnd, [v.velocity.width * xs / dp, v.velocity.height * ys / dp])
            })
            .simultaneousGesture(press == nil && release == nil ? nil : DragGesture(minimumDistance: 0).onChanged { v in
                guard !pressed else { return }
                pressed = true
                widget.handle(press, [v.location.x / dp, v.location.y / dp, 0])
                // With repeats: true onPress runs again while it stays down, after 400 ms and then every 50 ms.
                if node["repeats"].isTrue, press != nil {
                    let at = v.location
                    repeatTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        var n = 1
                        while !Task.isCancelled {
                            widget.handle(press, [at.x / dp, at.y / dp, n])
                            n += 1
                            try? await Task.sleep(for: .milliseconds(50))
                        }
                    }
                }
            }.onEnded { _ in
                pressed = false
                repeatTask?.cancel()
                repeatTask = nil
                widget.handle(release)
            })
    }
}

struct OwlClip: ViewModifier {
    let on: Bool
    let shape: RoundedRectangle

    func body(content: Content) -> some View {
        if on { content.clipShape(shape) } else { content }
    }
}

/// `animate x: tween(...)` or `spring(...)`, as a SwiftUI animation.
enum OwlAnimation {
    static func of(_ a: OwlValue?) -> Animation? {
        guard let a, a.object != nil else { return nil }
        if a["type"].string == "tween" {
            let d = max(0, a["duration"].number ?? 0.3)
            switch a["easing"].string {
            case "linear": return .linear(duration: d)
            case "in": return .easeIn(duration: d)
            case "out": return .easeOut(duration: d)
            default: return .easeInOut(duration: d)
            }
        }
        // Compose's spring: a damping ratio and a stiffness, for a unit mass.
        let stiffness = max(a["stiffness"].number ?? 300, 1)
        let damping = max(a["damping"].number ?? 0.6, 0.05)
        return .interpolatingSpring(mass: 1, stiffness: stiffness, damping: 2 * damping * stiffness.squareRoot())
    }
}

/// A background gradient (owl 10): its points are fractions of the node, and a radial one's radius a fraction
/// of the longer side.
struct OwlGradientFill: View {
    let gradient: OwlGradient
    let shape: RoundedRectangle

    var body: some View {
        GeometryReader { geo in
            let g = gradient
            if g.radial {
                shape.fill(RadialGradient(gradient: g.stops, center: UnitPoint(x: g.coord(0), y: g.coord(1)), startRadius: 0,
                                          endRadius: max(g.coord(2) * max(geo.size.width, geo.size.height), 0.01)))
            } else {
                shape.fill(LinearGradient(gradient: g.stops, startPoint: UnitPoint(x: g.coord(0), y: g.coord(1)), endPoint: UnitPoint(x: g.coord(2), y: g.coord(3))))
            }
        }
    }
}
