import Foundation

/// Commands a widget runs: `bash -c`, from the home folder, as the launcher's guest and Quickshell run them.
/// iOS runs none, as the launcher runs none without Linux.
enum OwlProcess {
    static var canRun: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    struct Result {
        var out: String
        var err: String
        var code: Int
        var timedOut: Bool
    }

    /// Runs [command] to its end, killed after [timeout] seconds; 124 is a timeout, as `timeout(1)` has it.
    static func run(_ command: String, home: String, timeout: Double) async -> Result {
        #if os(macOS)
        return await withCheckedContinuation { done in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/bash")
            p.arguments = ["-c", command]
            p.currentDirectoryURL = URL(fileURLWithPath: home)
            p.environment = environment()
            let out = Pipe(), err = Pipe()
            p.standardOutput = out
            p.standardError = err
            p.standardInput = FileHandle.nullDevice
            let collected = Collected()
            // Read as it comes, or a command that prints more than a pipe holds never ends.
            out.fileHandleForReading.readabilityHandler = { h in collected.add(h.availableData, err: false) }
            err.fileHandleForReading.readabilityHandler = { h in collected.add(h.availableData, err: true) }
            p.terminationHandler = { p in
                out.fileHandleForReading.readabilityHandler = nil
                err.fileHandleForReading.readabilityHandler = nil
                collected.add(out.fileHandleForReading.readDataToEndOfFile(), err: false)
                collected.add(err.fileHandleForReading.readDataToEndOfFile(), err: true)
                let (o, e, killed) = collected.result()
                done.resume(returning: Result(out: o, err: e, code: killed ? 124 : Int(p.terminationStatus), timedOut: killed))
            }
            do {
                try p.run()
            } catch {
                done.resume(returning: Result(out: "", err: "\(error)", code: 127, timedOut: false))
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + max(timeout, 1)) {
                if p.isRunning {
                    collected.markKilled()
                    p.terminate()
                    kill(p.processIdentifier, SIGKILL)
                }
            }
        }
        #else
        return Result(out: "", err: "commands don't run on iOS", code: 127, timedOut: false)
        #endif
    }

    /// A long-running command whose every line is handed to [line] on the main actor. [ended] runs when it
    /// exits. The returned closure stops it.
    @MainActor
    static func stream(_ command: String, home: String, line: @escaping @MainActor (String) -> Void, ended: @escaping @MainActor () -> Void) -> (() -> Void)? {
        #if os(macOS)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = ["-c", command]
        p.currentDirectoryURL = URL(fileURLWithPath: home)
        p.environment = environment()
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        let buffer = LineBuffer()
        out.fileHandleForReading.readabilityHandler = { h in
            let lines = buffer.add(h.availableData)
            if !lines.isEmpty { DispatchQueue.main.async { lines.forEach { line($0) } } }
        }
        p.terminationHandler = { _ in
            out.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async { ended() }
        }
        do { try p.run() } catch { return nil }
        return { if p.isRunning { p.terminate() } }
        #else
        return nil
        #endif
    }

    /// Starts something and forgets it.
    static func detach(_ argv: [String], home: String) {
        #if os(macOS)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: argv[0])
        p.arguments = Array(argv.dropFirst())
        p.currentDirectoryURL = URL(fileURLWithPath: home)
        p.environment = environment()
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        #endif
    }

    /// The user's PATH as a login shell has it: an app started from the Dock has only /usr/bin:/bin, where
    /// Homebrew's tools aren't. Store widgets are written for Arch, so GNU's date, sed, grep, find and awk
    /// come first where Homebrew has them (`brew install coreutils gnu-sed grep findutils gawk`).
    static func environment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let gnu = ["coreutils", "gnu-sed", "grep", "findutils", "gawk"].flatMap { ["/opt/homebrew/opt/\($0)/libexec/gnubin", "/usr/local/opt/\($0)/libexec/gnubin"] }
            .filter { FileManager.default.fileExists(atPath: $0) }
        let extra = gnu + ["/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin"]
        let path = (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin").split(separator: ":").map(String.init)
        env["PATH"] = (extra.filter { !path.contains($0) } + path).joined(separator: ":")
        return env
    }
}

private final class Collected: @unchecked Sendable {
    private let lock = NSLock()
    private var out = Data(), err = Data()
    private var killed = false
    // The most a command's output is kept to, as text is capped in Owl.js.
    private let cap = 4 << 20

    func add(_ d: Data, err isErr: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if isErr { if err.count < cap { err.append(d) } } else if out.count < cap { out.append(d) }
    }

    func markKilled() {
        lock.lock()
        killed = true
        lock.unlock()
    }

    func result() -> (String, String, Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (String(decoding: out, as: UTF8.self), String(decoding: err, as: UTF8.self), killed)
    }
}

private final class LineBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = Data()

    func add(_ d: Data) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        pending.append(d)
        var lines = [String]()
        while let i = pending.firstIndex(of: 0x0A) {
            lines.append(String(decoding: pending[pending.startIndex..<i], as: UTF8.self))
            pending.removeSubrange(pending.startIndex...i)
        }
        return lines
    }
}
