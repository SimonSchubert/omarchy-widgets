import Foundation
#if os(macOS)
import IOKit.ps
#endif

/// What the launcher reads from Android for android.*, read here from the Mac, in the shapes the
/// Quickshell runtime's owl-source answers with: what a Mac has, and null for what it hasn't.
enum OwlFacts {
    static func sysctl(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buf = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return nil }
        return String(cString: buf)
    }

    static func sysctlInt(_ name: String) -> Int64? {
        var v: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(name, &v, &size, nil, 0) == 0 else { return nil }
        return v
    }

    static func device() -> [String: Any] {
        ["model": sysctl("hw.model") ?? NSNull(), "maker": "Apple", "android": NSNull(), "sdk": NSNull(),
         "soc": sysctl("machdep.cpu.brand_string") ?? NSNull()]
    }

    static func system(launcher: String?) -> [String: Any] {
        let total = ProcessInfo.processInfo.physicalMemory
        var storage: [String: Any] = ["used": NSNull(), "total": NSNull()]
        if let a = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let size = (a[.systemSize] as? NSNumber)?.int64Value, let free = (a[.systemFreeSize] as? NSNumber)?.int64Value {
            storage = ["used": size - free, "total": size]
        }
        var uts = utsname()
        uname(&uts)
        let kernel = withUnsafeBytes(of: &uts.release) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        let abi = withUnsafeBytes(of: &uts.machine) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        let theme = try? String(contentsOfFile: NSHomeDirectory() + "/.local/state/omarchy/current/theme.name", encoding: .utf8)
        return [
            "memory": ["used": usedMemory().map { $0 as Any } ?? NSNull(), "total": total],
            "storage": storage,
            "display": NSNull(),
            "kernel": kernel,
            "uptime": Int(ProcessInfo.processInfo.systemUptime),
            "apps": NSNull(),
            "theme": theme?.split(separator: "\n").first.map(String.init) ?? NSNull(),
            "cpu": ["soc": sysctl("machdep.cpu.brand_string") ?? NSNull(), "hardware": NSNull(), "maker": "Apple",
                    "cores": ProcessInfo.processInfo.processorCount, "abi": abi, "maxMhz": NSNull()],
            "launcher": launcher ?? NSNull(), "codename": NSNull(), "build": NSNull(), "patch": NSNull(),
            "locale": Locale.current.identifier, "timezone": TimeZone.current.identifier,
            // No Arch here.
            "linux": NSNull(),
        ]
    }

    static func usedMemory() -> Int64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) }
        }
        guard r == KERN_SUCCESS else { return nil }
        let page = Int64(vm_kernel_page_size)
        // What Activity Monitor calls used: app memory, wired and compressed.
        return (Int64(stats.active_count) + Int64(stats.wire_count) + Int64(stats.compressor_page_count) - Int64(stats.purgeable_count)) * page
    }

    /// The battery, or nil on a Mac without one.
    static func battery() -> [String: Any]? {
        #if os(macOS)
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for ps in list {
            guard let d = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
                  d[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
            let cur = d[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            let charging = d[kIOPSIsChargingKey] as? Bool ?? false
            let ac = d[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            let full = d[kIOPSIsChargedKey] as? Bool ?? false
            let status = full ? "full" : charging ? "charging" : ac ? "not charging" : "discharging"
            var health: Any = NSNull()
            if let h = d["BatteryHealthCondition"] as? String { health = h } else if let h = d[kIOPSBatteryHealthKey] as? String { health = h }
            return ["level": max > 0 ? Int((Double(cur) * 100 / Double(max)).rounded()) : cur, "charging": ac, "status": status,
                    "plugged": ac ? "ac" : NSNull(), "health": health, "cycles": NSNull(), "technology": NSNull()]
        }
        #endif
        return nil
    }

    static func volume() async -> [String: Any] {
        #if os(macOS)
        let r = await OwlProcess.run("osascript -e 'set s to get volume settings' -e 'return (output volume of s as text) & \",\" & (output muted of s as text)'", home: NSHomeDirectory(), timeout: 5)
        let parts = r.out.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
        if parts.count == 2, let level = Int(parts[0]) {
            return ["level": level, "muted": parts[1] == "true", "max": 100, "output": ["type": "speaker", "name": NSNull()]]
        }
        #endif
        return ["level": NSNull(), "muted": NSNull(), "max": 100]
    }

    static func modes() -> [String: Any] {
        let dark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        return ["dnd": false, "saver": ProcessInfo.processInfo.isLowPowerModeEnabled, "ringer": "normal", "torch": NSNull(),
                "torchLevel": NSNull(), "dndAllows": "all", "airplane": false, "wifi": NSNull(), "bluetooth": NSNull(),
                "location": NSNull(), "rotate": NSNull(), "dark": dark, "brightness": NSNull(), "autoBrightness": false]
    }

    /// Bytes received and sent on every interface but loopback since boot.
    static func network() -> [String: Any] {
        var rx: UInt64 = 0, tx: UInt64 = 0
        var addrs: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&addrs) == 0 {
            var p = addrs
            while let a = p {
                let name = String(cString: a.pointee.ifa_name)
                if let sa = a.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_LINK), !name.hasPrefix("lo"),
                   let data = a.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    rx += UInt64(data.pointee.ifi_ibytes)
                    tx += UInt64(data.pointee.ifi_obytes)
                }
                p = a.pointee.ifa_next
            }
            freeifaddrs(addrs)
        }
        return ["rx": rx, "tx": tx, "mobileRx": NSNull(), "mobileTx": NSNull(), "uptime": ProcessInfo.processInfo.systemUptime]
    }

    static let noAlarm: [String: Any] = ["set": false, "time": NSNull(), "app": NSNull()]
    static let noAgents: [String: Any] = ["default": NSNull(), "installed": [Any]()]
    static let noDrawer: [String: Any] = ["apps": [Any](), "linux": NSNull(), "monochrome": false, "work": NSNull(), "updates": 0]
    static let noSim: [String: Any] = ["available": false, "present": false, "carrier": NSNull(), "signal": NSNull(), "data": NSNull(), "roaming": false]
    static let noModifiers: [String: Any] = ["ctrl": "off", "alt": "off", "shift": "off"]
}
