import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// What an OWL widget needs from the app it runs in, with defaults for a Mac. An app that knows better --
/// its own fonts, its own way to open a terminal -- subclasses it and overrides what it has to, as
/// OwlHost.qml is subclassed in a Quickshell shell.
@MainActor
open class OwlHost {
    public init() {}

    /// The fonts behind OWL's `mono` (everything by default), `sans` and `icon` (a Nerd Font, for
    /// weatherIcon() and `font: icon`). The first one installed wins.
    open var monoFamilies = ["JetBrainsMono Nerd Font", "JetBrainsMono NF", "JetBrains Mono", "Menlo"]
    open var sansFamilies: [String] = []
    open var iconFamilies = ["Symbols Nerd Font", "JetBrainsMono Nerd Font", "JetBrainsMono NF"]

    /// The board's gaps and tile borders in dp, and its tiles' glass (owl 12 and 13), for a widget that frames
    /// its own cards like the board's tiles. Omarchy's Hyprland defaults.
    open var gapsIn: Double = 5
    open var gapsOut: Double = 10
    open var borderWidth: Double = 2
    open var tileOpacity: Double = 1
    open var tileFrost: Double = 0

    open var home: String { NSHomeDirectory() }

    /// Where `state ... persist` and `history(...) persist` are kept. Secrets go to the Keychain instead.
    open var stateDir: String {
        #if os(macOS)
        return home + "/Library/Application Support/owl"
        #else
        return (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? home) + "/owl"
        #endif
    }

    /// The host app's version, which android.system answers as `launcher`.
    open var launcherVersion: String? = nil

    /// android.media: {playing, title, artist, album, app}. Nothing reads other apps' playback on a Mac
    /// without private frameworks, so nothing plays unless an app says otherwise.
    open var media: [String: Any] { ["playing": false, "title": NSNull(), "artist": NSNull(), "album": NSNull(), "app": NSNull()] }

    /// A widget's text field took or lost focus: a phone raises its keyboard.
    open func fieldFocused(_ focused: Bool) {}

    /// The actions a widget's handlers call, but run(), refresh(), screen(), close() and sound(), which the
    /// widget does itself.
    open func act(_ widget: OwlWidget, _ name: String, _ args: [String?]) { defaultAct(widget, name, args) }

    public func defaultAct(_ widget: OwlWidget, _ name: String, _ args: [String?]) {
        func s(_ i: Int) -> String { i < args.count ? args[i] ?? "" : "" }
        switch name {
        case "terminal": openTerminal(s(0))
        case "app": OwlProcess.detach(["/bin/bash", "-c", s(0)], home: home)
        case "url": openURL(s(0))
        case "copy": copy(s(0))
        case "notify": notify(s(0), s(1))
        case "share":
            copy(s(0))
            notify("copied", s(0))
        case "media": mediaAction(s(0), widget)
        case "volume":
            if args.count > 1, s(1) != "media" {
                widget.report("volume(..., \"\(s(1))\") sets a phone's \(s(1)) volume, which a Mac does not have")
            } else { volume(s(0)) }
        case "dnd": widget.report("dnd(...) switches Focus, which only Shortcuts and the user can do on a Mac")
        case "settings": widget.report("settings(\"\(s(0))\") opens Android's settings panels, which a Mac does not have")
        case "pressKey", "typeText", "latch":
            widget.report("\(name)(...) types into the window under the on-screen keyboard, which a Mac does not have")
        case "launcher": widget.report("launcher(\"\(s(0))\") opens the Android launcher's own screens; this app has none")
        // No torch and no haptics here: a widget's button just does nothing.
        case "torch", "haptic": break
        case "androidApp", "notification":
            widget.report("\(name)() opens Android apps and notifications, which a Mac does not have")
        case "open": widget.report("open(\"\(s(0))\") opens an app or agent from the launcher's drawer, which this app does not have")
        case "ask": widget.report("ask(...) sends a prompt to the launcher's coding agent, which this app does not have")
        case "appAction": widget.report("appAction(\"\(s(0))\", ...) acts on an app in the launcher's drawer, which this app does not have")
        case "workApps": widget.report("workApps(...) pauses an Android work profile, which a Mac does not have")
        default: break
        }
    }

    /// `terminal(cmd)`: the command in a new Terminal window, which stays open after it.
    open func openTerminal(_ command: String) {
        #if os(macOS)
        let script = "tell application \"Terminal\"\nactivate\ndo script \(Self.appleScriptString(command))\nend tell"
        OwlProcess.detach(["/usr/bin/osascript", "-e", script], home: home)
        #endif
    }

    open func openURL(_ text: String) {
        guard let url = URL(string: text) else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }

    open func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }

    open func notify(_ title: String, _ body: String) {
        #if os(macOS)
        // UserNotifications needs an app bundle; `swift run` has none.
        OwlProcess.detach(["/usr/bin/osascript", "-e", "display notification \(Self.appleScriptString(body)) with title \(Self.appleScriptString(title))"], home: home)
        #endif
    }

    open func mediaAction(_ op: String, _ widget: OwlWidget) {
        widget.report("media(\"\(op)\") controls the phone's player; a Mac has no player this app can drive")
    }

    open func volume(_ v: String) {
        #if os(macOS)
        let set: String
        switch v {
        case "up": set = "set volume output volume ((output volume of (get volume settings)) + 6)"
        case "down": set = "set volume output volume ((output volume of (get volume settings)) - 6)"
        case "mute": set = "set volume with output muted"
        case "unmute": set = "set volume without output muted"
        case "toggle": set = "set volume output muted (not (output muted of (get volume settings)))"
        default:
            guard let n = Double(v) else { return }
            set = "set volume output volume \(Int(max(0, min(100, n))))"
        }
        OwlProcess.detach(["/usr/bin/osascript", "-e", set], home: home)
        #endif
    }

    static func appleScriptString(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    // ------------------------------------------------------------- fonts

    private var familyCache = [String: String]()

    func firstInstalled(_ families: [String], fallback: String) -> String {
        let key = families.joined(separator: "|")
        if let f = familyCache[key] { return f }
        #if os(macOS)
        let installed = Set(NSFontManager.shared.availableFontFamilies)
        #else
        let installed = Set(UIFont.familyNames)
        #endif
        let f = families.first { installed.contains($0) } ?? fallback
        familyCache[key] = f
        return f
    }

    var monoFamily: String { firstInstalled(monoFamilies, fallback: "Menlo") }
    /// "" is the system font.
    var sansFamily: String { firstInstalled(sansFamilies, fallback: "") }
    var iconFamily: String { firstInstalled(iconFamilies, fallback: monoFamily) }
}
