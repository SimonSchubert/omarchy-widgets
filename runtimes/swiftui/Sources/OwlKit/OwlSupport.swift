import AVFoundation
import CoreText
import Foundation
import Security
import SwiftUI
#if os(macOS)
import AppKit
public typealias OwlPlatformImage = NSImage
#else
import UIKit
public typealias OwlPlatformImage = UIImage
#endif

/// `state x = null secret`: in the Keychain, one item per widget file, as the launcher keeps them in Android's
/// keystore. Owl.js binds each to the servers it was typed in for.
enum OwlSecrets {
    private static let service = "owl widget secrets"

    private static func query(_ path: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: path]
    }

    static func read(_ path: String) -> String? {
        var q = query(path)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(decoding: d, as: UTF8.self)
    }

    /// nil deletes them: a widget that's been signed out of keeps nothing.
    static func write(_ path: String, _ json: String?) {
        let q = query(path)
        guard let json else {
            SecItemDelete(q as CFDictionary)
            return
        }
        let data = Data(json.utf8)
        if SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary) == errSecItemNotFound {
            var add = q
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
        }
    }
}

/// A path a widget names, as a URL: "~/pics/a.png", "/usr/...", an asset's data: URL, or a web address.
/// Android's app icons (`app:`, `icon:`) have nothing to show here.
func owlURL(_ src: String, home: String) -> URL? {
    if src.isEmpty || src.hasPrefix("app:") || src.hasPrefix("icon:") { return nil }
    if src.hasPrefix("~/") { return URL(fileURLWithPath: home + src.dropFirst()) }
    if src.hasPrefix("/") { return URL(fileURLWithPath: src) }
    return URL(string: src)
}

/// The bytes behind a URL: data: decoded, a file read, the web fetched.
func owlData(_ url: URL) async -> Data? {
    if url.scheme == "data" {
        let s = url.absoluteString
        guard let comma = s.firstIndex(of: ",") else { return nil }
        let head = s[..<comma], body = String(s[s.index(after: comma)...])
        return head.hasSuffix(";base64") ? Data(base64Encoded: body, options: .ignoreUnknownCharacters) : body.removingPercentEncoding.map { Data($0.utf8) }
    }
    if url.isFileURL { return FileManager.default.contents(atPath: url.path) }
    guard let (d, r) = try? await URLSession.shared.data(from: url), ((r as? HTTPURLResponse)?.statusCode ?? 200) < 400 else { return nil }
    return d
}

/// Images by their src, shared by every widget: the launcher keeps 32 a widget; a board of them keeps more.
@MainActor
@Observable
final class OwlImages {
    static let shared = OwlImages()
    @ObservationIgnored private let cache = NSCache<NSString, OwlPlatformImage>()
    @ObservationIgnored private var loading = Set<String>()
    @ObservationIgnored private var failed = Set<String>()
    /// Bumped as one arrives, for the views waiting on it.
    private(set) var loaded = 0

    init() { cache.countLimit = 256 }

    func image(_ src: String, home: String) -> OwlPlatformImage? {
        _ = loaded
        if let i = cache.object(forKey: src as NSString) { return i }
        guard !loading.contains(src), !failed.contains(src), let url = owlURL(src, home: home) else { return nil }
        loading.insert(src)
        Task {
            let data = await owlData(url)
            self.loading.remove(src)
            if let data, let img = OwlPlatformImage(data: data) {
                self.cache.setObject(img, forKey: src as NSString)
                self.loaded += 1
            } else {
                self.failed.insert(src)
            }
        }
        return nil
    }
}

extension Image {
    init(owl image: OwlPlatformImage) {
        #if os(macOS)
        self.init(nsImage: image)
        #else
        self.init(uiImage: image)
        #endif
    }
}

/// sound(...): one at a time, a new one in place of the last; "stop" stops it.
@MainActor
final class OwlSound {
    private var player: AVAudioPlayer?

    func play(_ src: String, home: String, report: @escaping (String) -> Void) {
        player?.stop()
        player = nil
        if src == "stop" || src.isEmpty { return }
        guard let url = owlURL(src, home: home) else { return }
        Task {
            guard let data = await owlData(url) else { return report("can't load the sound \(src.prefix(80))") }
            do {
                let p = try AVAudioPlayer(data: data)
                self.player = p
                p.play()
            } catch {
                report("can't play the sound \(src.prefix(80))")
            }
        }
    }
}

/// A widget's own fonts (owl 10): an asset, an https URL or a file, registered for this process. Up to 8 a
/// file, as on the launcher.
@MainActor
final class OwlFonts {
    private weak var widget: OwlWidget?
    private var families = [String: String?]()

    init(widget: OwlWidget) { self.widget = widget }

    /// The family once it has loaded, nil until then.
    func family(_ src: String) -> String? {
        if let f = families[src] { return f }
        guard families.count < 8, let widget, let url = owlURL(src, home: widget.host.home) else { return nil }
        families[src] = .some(nil)
        Task {
            guard let data = await owlData(url), let provider = CGDataProvider(data: data as CFData), let font = CGFont(provider) else {
                self.widget?.report("can't load the font \(src.prefix(80))")
                return
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterGraphicsFont(font, &error)
            let name = font.postScriptName as String? ?? font.fullName as String?
            self.families[src] = .some(name)
            self.widget?.fontLoaded()
        }
        return nil
    }
}
