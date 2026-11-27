import Foundation
import Observation
import SwiftUI

/// One OWL widget file, live: compiled by Owl.js, its sources run here, drawn by [OwlTileView]. The Swift
/// side of OwlWidget.qml and OwlSource.qml.
///
/// What the launcher writes to `.errors/<file>.txt` beside the widget -- the compile error with a caret, then
/// runtime problems as they happen -- this writes too, because that file is what an agent writing a widget is
/// told to read. `state x = ... persist` survives in <stateDir>/<file>.json, and `state x = null secret` in
/// the Keychain.
@MainActor
@Observable
public final class OwlWidget: Identifiable {
    public nonisolated var id: String { path }
    public nonisolated let path: String
    public let host: OwlHost

    public var theme: OwlTheme {
        didSet {
            guard theme != oldValue else { return }
            bridge?.invalidate()
            render()
        }
    }

    /// Sources run and animations play only while this is true: the board is up.
    public var active = false {
        didSet { if active != oldValue { restartRunning() } }
    }

    /// The tile in grid cells, and one dp in points.
    public var cols = 3
    public var rows = 2
    public var dp: Double = 1
    /// The board, for screenWidth and screenHeight, in points.
    public var screenSize = CGSize(width: 360, height: 720)

    public private(set) var program: OwlProgram?
    public private(set) var tree: OwlTree?
    public private(set) var screenTree: OwlTree?
    public private(set) var screenOpen = false
    public private(set) var error = ""
    public private(set) var problems: [String] = []
    /// Bumped every animation frame: a Canvas draws again.
    public private(set) var frameCount = 0
    /// Bumped as a font of the widget's own loads.
    public private(set) var fontsLoaded = 0

    public var fileName: String { (path as NSString).lastPathComponent }
    public var dir: String { (path as NSString).deletingLastPathComponent }
    public var name: String { program?.name ?? (fileName as NSString).deletingPathExtension }
    public var isFace: Bool { program?.isFace ?? false }
    public var level: Int { program?.level ?? 1 }
    /// Cells, columns × rows.
    public var size: (Int, Int) { program?.size ?? (3, 2) }

    @ObservationIgnored private var bridge: OwlBridge?
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    @ObservationIgnored private var stopStreams: [() -> Void] = []
    @ObservationIgnored private var frameTimer: Timer?
    @ObservationIgnored private var frameStart = Date()
    @ObservationIgnored private var renderQueued = false
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var errorsTask: Task<Void, Never>?
    @ObservationIgnored private var tileSize = CGSize.zero
    @ObservationIgnored private var savedPersisted = ""
    @ObservationIgnored private var savedSecrets = ""
    @ObservationIgnored private var watcher: DispatchSourceFileSystemObject?
    @ObservationIgnored private var lastSource = ""
    @ObservationIgnored let sound = OwlSound()
    @ObservationIgnored var fonts: OwlFonts!

    public init(path: String, host: OwlHost, theme: OwlTheme) {
        self.path = path
        self.host = host
        self.theme = theme
        fonts = OwlFonts(widget: self)
        load()
        watch()
    }

    // ------------------------------------------------------------ load

    /// Reads and compiles the file again: on a change on disk, or when asked.
    public func load() {
        stopRunning()
        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            fail("can't read \(path)")
            return
        }
        lastSource = source
        let persisted = (try? String(contentsOfFile: stateFile, encoding: .utf8)) ?? "{}"
        let secrets = OwlSecrets.read(path) ?? "{}"
        savedPersisted = persisted.trimmingCharacters(in: .whitespacesAndNewlines)
        savedSecrets = secrets
        let bridge: OwlBridge
        do {
            bridge = try OwlBridge(callbacks: callbacks())
        } catch {
            fail("\(error)")
            return
        }
        switch bridge.load(source, persisted: persisted, secrets: secrets) {
        case .failure(let e):
            fail(e.message)
        case .success(let program):
            self.bridge = bridge
            self.program = program
            error = ""
            problems = []
            writeErrors()
            render()
            // Takes in each `on` trigger's first value, and runs the ones that say `first`.
            bridge.checkTriggers()
            restartRunning()
        }
    }

    private func fail(_ message: String) {
        error = message
        program = nil
        bridge = nil
        tree = nil
        screenTree = nil
        writeErrors()
    }

    /// The file changing on disk loads it again, as the launcher's tiles do.
    private func watch() {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        let w = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .rename, .delete, .extend], queue: .main)
        w.setEventHandler { [weak self] in
            guard let self else { return }
            // An editor that saves by renaming leaves this watching the old file.
            if w.data.contains(.rename) || w.data.contains(.delete) {
                w.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { MainActor.assumeIsolated { self.watch(); self.reloadIfChanged() } }
                return
            }
            self.reloadIfChanged()
        }
        w.setCancelHandler { close(fd) }
        w.resume()
        watcher = w
    }

    private func reloadIfChanged() {
        guard let s = try? String(contentsOfFile: path, encoding: .utf8), s != lastSource else { return }
        load()
    }

    // ------------------------------------------------------------ host

    private func callbacks() -> OwlBridge.Callbacks {
        var c = OwlBridge.Callbacks()
        c.theme = { [weak self] name in self?.theme.colors[name] }
        c.tile = { [weak self] name in self?.tile(name) }
        c.act = { [weak self] name, args in self?.act(name, args) }
        c.runInto = { [weak self] cmd, slot in self?.runInto(cmd, slot) }
        c.post = { [weak self] url, body, json, headers, slot, method in self?.post(url, body, json, headers, slot, method) }
        c.report = { [weak self] m in self?.report(m) }
        c.changed = { [weak self] in self?.changed() }
        return c
    }

    private func tile(_ name: String) -> Any? {
        switch name {
        case "linux": return OwlProcess.canRun
        case "cols": return cols
        case "rows": return rows
        case "tileWidth": return tileSize.width / dp
        case "tileHeight": return tileSize.height / dp
        case "screenWidth": return screenSize.width / dp
        case "screenHeight": return screenSize.height / dp
        // What a navigation bar covers of a face: there is none here.
        case "screenInset": return 0
        // Omarchy's corners are square.
        case "corners": return 0
        case "gapsIn": return host.gapsIn
        case "gapsOut": return host.gapsOut
        case "borderWidth": return host.borderWidth
        case "tileOpacity": return host.tileOpacity
        case "tileFrost": return host.tileFrost
        default: return nil
        }
    }

    /// The tile's size inside its padding, in points, which tileWidth and tileHeight read.
    public func setTileSize(_ s: CGSize) {
        guard s != tileSize else { return }
        tileSize = s
        bridge?.invalidate()
        queueRender()
    }

    private func changed() {
        queueRender()
        saveLater()
    }

    /// Coalesced: a handler that sets three states draws once.
    private func queueRender() {
        guard !renderQueued else { return }
        renderQueued = true
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.renderQueued = false
                self?.render()
            }
        }
    }

    private func render() {
        guard let bridge else { return }
        tree = bridge.render(screen: false)
        if screenOpen { screenTree = bridge.render(screen: true) }
    }

    // ------------------------------------------------------- what views call

    /// Runs a handler: onTap's x and y, a Slider's value...
    public func handle(_ id: Int?, _ args: [Any] = []) {
        guard let id, let bridge else { return }
        bridge.handle(id, args)
    }

    func draw(_ id: Int, width: Double, height: Double) -> [OwlDrawOp] {
        bridge?.draw(id, width: width, height: height) ?? []
    }

    public func closeScreen() {
        guard screenOpen else { return }
        screenOpen = false
        screenTree = nil
    }

    // --------------------------------------------------------- running

    private func stopRunning() {
        tasks.forEach { $0.cancel() }
        tasks = []
        stopStreams.forEach { $0() }
        stopStreams = []
        frameTimer?.invalidate()
        frameTimer = nil
    }

    /// Sources, triggers and the frame clock, while [active].
    private func restartRunning() {
        stopRunning()
        guard active, let bridge, let program else { return }
        for spec in bridge.sources() { start(spec) }
        for t in bridge.everyTriggers() {
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(max(t.seconds, 0.05)))
                    if Task.isCancelled { return }
                    self?.bridge?.fire(t.index)
                }
            })
        }
        if bridge.hasAt() {
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    self?.bridge?.tick(Date().timeIntervalSince1970)
                    try? await Task.sleep(for: .seconds(1))
                }
            })
        }
        if program.animated {
            // `time` is seconds since the frame clock started, as the launcher's: it restarts when the board reopens.
            frameStart = Date()
            let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.frame() }
            }
            RunLoop.main.add(timer, forMode: .common)
            frameTimer = timer
        }
    }

    private func frame() {
        guard let bridge else { return }
        bridge.frame(Date().timeIntervalSince(frameStart))
        frameCount &+= 1
        if tree?.readsTime == true { render() }
    }

    /// refresh(): every source runs again now.
    public func refresh() { restartRunning() }

    private func start(_ spec: OwlSourceSpec) {
        let slot = spec.slot
        let every = max(spec.every ?? 60, 0.1)
        switch spec.kind {
        case "clock":
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    let now = Date().timeIntervalSince1970
                    // Whole seconds unless the widget ticks faster: `now - fed` and fmtTime() are written for an integer clock.
                    self?.bridge?.setSourceJSON(slot, every >= 1 ? "\(Int(now.rounded()))" : "\(now)")
                    // On its own boundaries, so `every 1m` turns over with the minute.
                    let ms = every * 1000
                    let wait = (ms - (now * 1000).truncatingRemainder(dividingBy: ms) + 5) / 1000
                    try? await Task.sleep(for: .seconds(wait))
                }
            })
        case "cmd":
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    guard let self, let bridge = self.bridge else { return }
                    let command = bridge.sourceArg(spec.index)
                    // A command with a value still loading in it is null, and waits for it, as on the launcher.
                    if Self.loading(command) {
                        try? await Task.sleep(for: .seconds(1))
                        continue
                    }
                    let timeout = spec.timeout ?? 10
                    let r = await OwlProcess.run(command, home: self.host.home, timeout: timeout)
                    if Task.isCancelled { return }
                    if r.timedOut { self.report("\(spec.name): timed out after \(Int(timeout))s") }
                    if spec.status {
                        bridge.setSourceStatus(slot, code: r.code, out: r.out, err: r.err, json: spec.json, ok: r.code == 0)
                    } else {
                        bridge.setSourceText(slot, r.out)
                    }
                    try? await Task.sleep(for: .seconds(every))
                }
            })
        case "http":
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    guard let self, let bridge = self.bridge else { return }
                    if Self.loading(bridge.sourceArg(spec.index)) {
                        try? await Task.sleep(for: .seconds(1))
                        continue
                    }
                    await self.fetch(spec)
                    try? await Task.sleep(for: .seconds(every))
                }
            })
        case "stream":
            startStream(spec)
        case "file":
            tasks.append(Task { [weak self] in
                var last: (String, Date?)? = nil
                while !Task.isCancelled {
                    guard let self, let bridge = self.bridge else { return }
                    let file = self.expand(bridge.sourceArg(spec.index))
                    let mtime = (try? FileManager.default.attributesOfItem(atPath: file))?[.modificationDate] as? Date
                    if last == nil || last!.0 != file || last!.1 != mtime {
                        last = (file, mtime)
                        if let text = try? String(contentsOfFile: file, encoding: .utf8) { bridge.setSourceText(slot, text) }
                        else { bridge.setSourceJSON(slot, "null") }
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            })
        case "android.device", "android.system", "android.volume", "android.modes", "android.network", "android.battery":
            let wait = spec.kind == "android.battery" ? 30 : every
            tasks.append(Task { [weak self] in
                while !Task.isCancelled {
                    guard let self else { return }
                    let v: Any
                    switch spec.kind {
                    case "android.device": v = OwlFacts.device()
                    case "android.system": v = OwlFacts.system(launcher: self.host.launcherVersion)
                    case "android.volume": v = await OwlFacts.volume()
                    case "android.modes": v = OwlFacts.modes()
                    case "android.network": v = OwlFacts.network()
                    default: v = OwlFacts.battery() ?? NSNull()
                    }
                    if Task.isCancelled { return }
                    self.bridge?.setSourceJSON(slot, Self.json(v))
                    try? await Task.sleep(for: .seconds(wait))
                }
            })
        // Pushed once rather than polled: what a Mac has none of.
        case "android.notifications", "android.apps", "android.recent": bridge?.setSourceJSON(slot, "[]")
        case "android.agents": bridge?.setSourceJSON(slot, Self.json(OwlFacts.noAgents))
        case "android.drawer": bridge?.setSourceJSON(slot, Self.json(OwlFacts.noDrawer))
        case "android.alarm": bridge?.setSourceJSON(slot, Self.json(OwlFacts.noAlarm))
        case "android.sim": bridge?.setSourceJSON(slot, Self.json(OwlFacts.noSim))
        case "android.modifiers": bridge?.setSourceJSON(slot, Self.json(OwlFacts.noModifiers))
        case "android.media": bridge?.setSourceJSON(slot, Self.json(host.media))
        default: break
        }
    }

    /// Owl.js shows a URL or command that waits on a value still loading as null.
    static func loading(_ arg: String) -> Bool { arg == "null" || arg.isEmpty }

    static func json(_ v: Any) -> String {
        guard JSONSerialization.isValidJSONObject(v), let d = try? JSONSerialization.data(withJSONObject: v) else {
            return v is NSNull ? "null" : "\(v)"
        }
        return String(decoding: d, as: UTF8.self)
    }

    private func expand(_ p: String) -> String {
        p.hasPrefix("~/") ? host.home + p.dropFirst() : p
    }

    private func fetch(_ spec: OwlSourceSpec) async {
        guard let bridge else { return }
        let text = bridge.sourceArg(spec.index)
        guard let url = URL(string: text) else {
            report("\(spec.name): not a URL: \(text.prefix(80))")
            return
        }
        var req = URLRequest(url: url, timeoutInterval: max(spec.timeout ?? 10, 1))
        for (k, v) in bridge.sourceHeaders(spec.index) { req.setValue(v, forHTTPHeaderField: k) }
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if Task.isCancelled { return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(decoding: data, as: UTF8.self)
            let ok = (200..<300).contains(code)
            if spec.status { bridge.setSourceStatus(spec.slot, code: code, out: body, err: "", json: spec.json, ok: ok) }
            else if ok { bridge.setSourceText(spec.slot, body) }
            else { report("\(spec.name): HTTP \(code) from \(text)") }
        } catch {
            if Task.isCancelled { return }
            let timedOut = (error as? URLError)?.code == .timedOut
            report("\(spec.name): \(timedOut ? "timed out" : error.localizedDescription)")
            if spec.status { bridge.setSourceStatus(spec.slot, code: timedOut ? 124 : 0, out: "", err: error.localizedDescription, json: spec.json, ok: false) }
        }
    }

    /// One long-running command; every line is a new value. One that ends starts again after a pause, so a
    /// command that dies on start doesn't spin.
    private func startStream(_ spec: OwlSourceSpec) {
        guard active, let bridge else { return }
        let stop = OwlProcess.stream(bridge.sourceArg(spec.index), home: host.home, line: { [weak self] line in
            self?.bridge?.setSourceText(spec.slot, line)
        }, ended: { [weak self] in
            guard let self, self.active else { return }
            self.tasks.append(Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled { self?.startStream(spec) }
            })
        })
        if let stop { stopStreams.append(stop) }
    }

    // ------------------------------------------------------------ actions

    /// run(), refresh(), screen(), close() and sound() are the widget's own; the rest -- terminal, app, url,
    /// media, launcher... -- are the host's.
    private func act(_ name: String, _ args: [String?]) {
        let a0 = args.first ?? nil
        switch name {
        case "run":
            let command = a0 ?? ""
            Task { [weak self] in
                guard let self else { return }
                _ = await OwlProcess.run(command, home: self.host.home, timeout: 600)
                self.refresh()
            }
        case "refresh": refresh()
        case "screen":
            guard program?.hasScreen == true, let bridge else { return }
            screenOpen = true
            screenTree = bridge.render(screen: true)
        case "close": closeScreen()
        case "sound": if let a0 { sound.play(a0, home: host.home) { [weak self] m in self?.report(m) } }
        default: host.act(self, name, args)
        }
    }

    private func runInto(_ command: String, _ slot: Int) {
        Task { [weak self] in
            guard let self else { return }
            let r = await OwlProcess.run(command, home: self.host.home, timeout: 600)
            self.bridge?.setStateText(slot, r.out)
        }
    }

    /// post(url, body, headers): with a slot, the answer lands there as {code, ok, out}; a 2xx refreshes the
    /// widget's sources, since what it changed shows in them.
    private func post(_ text: String, _ body: String, _ json: Bool, _ headers: [String: String], _ slot: Int, _ method: String) {
        guard let url = URL(string: text) else { return }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        var typed = false
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
            if k.lowercased() == "content-type" { typed = true }
        }
        if json && !typed { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        req.httpBody = Data(body.utf8)
        Task { [weak self] in
            let code: Int, answer: String
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                code = (response as? HTTPURLResponse)?.statusCode ?? 0
                answer = String(decoding: data, as: UTF8.self)
            } catch {
                code = 0
                answer = ""
            }
            guard let self else { return }
            let ok = (200..<300).contains(code)
            if !ok && slot < 0 { self.report("post: HTTP \(code) from \(text.split(separator: "?").first.map(String.init) ?? text)\(text.contains("?") ? "?…" : "")") }
            if slot >= 0 { self.bridge?.setPostAnswer(slot, code: code, text: answer) }
            if ok { self.refresh() }
        }
    }

    // --------------------------------------------------------- persistence

    private var stateFile: String { host.stateDir + "/" + fileName + ".json" }

    private func saveLater() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled { self?.save() }
        }
    }

    private func save() {
        guard let bridge else { return }
        let secrets = bridge.secrets()
        if secrets != savedSecrets {
            savedSecrets = secrets
            OwlSecrets.write(path, secrets == "{}" ? nil : secrets)
        }
        let data = bridge.persisted()
        guard data != "{}", data != savedPersisted else { return }
        savedPersisted = data
        try? FileManager.default.createDirectory(atPath: host.stateDir, withIntermediateDirectories: true)
        try? (data + "\n").write(toFile: stateFile, atomically: true, encoding: .utf8)
    }

    // ------------------------------------------------------------- errors

    public func report(_ message: String) {
        guard !problems.contains(message) else { return }
        problems = Array((problems + [message]).suffix(20))
        errorsTask?.cancel()
        errorsTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { self?.writeErrors() }
        }
    }

    private func writeErrors() {
        var text = error.isEmpty ? "" : error + "\n"
        if !problems.isEmpty { text += problems.joined(separator: "\n") + "\n" }
        let errors = dir + "/.errors"
        let file = errors + "/" + (fileName as NSString).deletingPathExtension + ".txt"
        // Nothing to say and nothing said before: no folder made in someone's widgets for it.
        if text.isEmpty && !FileManager.default.fileExists(atPath: file) { return }
        try? FileManager.default.createDirectory(atPath: errors, withIntermediateDirectories: true)
        try? text.write(toFile: file, atomically: true, encoding: .utf8)
    }

    // -------------------------------------------------------------- fonts

    /// A `font` as a family name: mono, sans, serif, icon, or since owl 10 a font of the widget's own -- an
    /// asset, an https URL or a file -- which draws in the mono font until it has loaded.
    func family(_ name: String?) -> String {
        _ = fontsLoaded
        switch name {
        case nil, "", "mono": return host.monoFamily
        case "sans": return host.sansFamily
        case "serif": return "Times New Roman"
        case "icon": return host.iconFamily
        default:
            if level < 10 { return host.monoFamily }
            return fonts.family(name!) ?? host.monoFamily
        }
    }

    func fontLoaded() { fontsLoaded += 1 }
}
