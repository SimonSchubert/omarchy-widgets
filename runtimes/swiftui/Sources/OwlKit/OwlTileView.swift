import SwiftUI

/// A widget as a tile on a board, framed as the launcher frames one: the theme's background at 0.88, a 2 dp
/// border in its muted color, the file's padding. A face has neither: its own background, the whole page.
/// The compile error, caret and all, shows in the tile instead of it.
public struct OwlTileView: View {
    let widget: OwlWidget

    public init(widget: OwlWidget) { self.widget = widget }

    public var body: some View {
        let dp = widget.dp
        let face = widget.isFace
        let padding = (widget.program?.padding ?? 12) * dp
        ZStack {
            if face {
                if let tree = widget.tree, !tree.background.isNull {
                    OwlNodeView(node: OwlNode(kind: "Box", p: ["background": tree.background], level: widget.level), widget: widget)
                }
            } else {
                Rectangle().fill(widget.theme.color("background").opacity(0.88))
            }
            Group {
                if !widget.error.isEmpty {
                    ScrollView {
                        Text(widget.error)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(widget.theme.color("red"))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .textSelection(.enabled)
                    }
                } else if let root = widget.tree?.root {
                    OwlNodeView(node: root, widget: widget)
                }
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { widget.setTileSize($0) }
            .padding(padding)
            if !face {
                Rectangle().strokeBorder(widget.theme.color("muted"), lineWidth: 2 * dp).allowsHitTesting(false)
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .gesture(widget.tree?.onTap == nil ? nil : SpatialTapGesture().onEnded { v in
            widget.handle(widget.tree?.onTap, [(v.location.x - padding) / dp, (v.location.y - padding) / dp])
        })
        .sheet(isPresented: Binding(get: { widget.screenOpen }, set: { if !$0 { widget.closeScreen() } })) {
            OwlScreenView(widget: widget)
        }
    }
}

/// What screen() opens: the widget's `screen { }`, full size, with its title and a way back.
public struct OwlScreenView: View {
    let widget: OwlWidget

    public init(widget: OwlWidget) { self.widget = widget }

    public var body: some View {
        let dp = widget.dp
        VStack(spacing: 0) {
            HStack {
                Text(widget.screenTree?.title ?? widget.name)
                    .font(owlFont(widget.family("mono"), size: 16 * dp))
                    .foregroundStyle(widget.theme.color("foreground"))
                Spacer()
                Button("close") { widget.closeScreen() }
                    .buttonStyle(.plain)
                    .font(owlFont(widget.family("mono"), size: 13 * dp))
                    .foregroundStyle(widget.theme.color("accent"))
                    .keyboardShortcut(.cancelAction)
            }
            .padding(12 * dp)
            if let root = widget.screenTree?.root {
                OwlNodeView(node: root, widget: widget).padding(12 * dp)
            }
        }
        .frame(minWidth: 360, idealWidth: widget.screenSize.width, minHeight: 480, idealHeight: widget.screenSize.height)
        .background(widget.theme.color("background"))
    }
}
