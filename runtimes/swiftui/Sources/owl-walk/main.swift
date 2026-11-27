// Runs ../quickshell/test/walk.js under JavaScriptCore instead of node, with just enough of node for it
// (require of fs, path and module, process, console), so test/run.sh can check that Owl.js prints the same
// bytes in the engine this runtime ships as in node:
//
//   owl-walk <walk.js> <Owl.js> <widget.owl> <fixture.json>
import Foundation
import JavaScriptCore

let args = CommandLine.arguments
guard args.count == 5 else {
    FileHandle.standardError.write("usage: owl-walk <walk.js> <Owl.js> <widget.owl> <fixture.json>\n".data(using: .utf8)!)
    exit(2)
}

let ctx = JSContext()!
var failed = false
ctx.exceptionHandler = { _, e in
    FileHandle.standardError.write("owl-walk: \(e?.toString() ?? "?")\n\(e?.objectForKeyedSubscript("stack")?.toString() ?? "")\n".data(using: .utf8)!)
    failed = true
}

let readText: @convention(block) (String) -> JSValue = { path in
    guard let s = try? String(contentsOfFile: path, encoding: .utf8) else { return JSValue(nullIn: ctx) }
    return JSValue(object: s, in: ctx)
}
let readBytes: @convention(block) (String) -> JSValue = { path in
    guard let d = FileManager.default.contents(atPath: path) else { return JSValue(nullIn: ctx) }
    let a = ctx.objectForKeyedSubscript("Uint8Array").construct(withArguments: [d.count])!
    a.invokeMethod("set", withArguments: [Array(d).map { Int($0) }])
    return a
}
let out: @convention(block) (String) -> Void = { FileHandle.standardOutput.write($0.data(using: .utf8)!) }
let err: @convention(block) (String) -> Void = { FileHandle.standardError.write($0.data(using: .utf8)!) }
ctx.setObject(readText, forKeyedSubscript: "__readText" as NSString)
ctx.setObject(readBytes, forKeyedSubscript: "__readBytes" as NSString)
ctx.setObject(out, forKeyedSubscript: "__out" as NSString)
ctx.setObject(err, forKeyedSubscript: "__err" as NSString)
ctx.setObject(["jsc"] + Array(args[1...]), forKeyedSubscript: "__argv" as NSString)

ctx.evaluateScript("""
var process = { argv: __argv, stderr: { write: __err }, exit: function(c) { throw new Error("exit " + c) } }
var console = { log: function() { __out(Array.prototype.join.call(arguments, " ") + "\\n") } }
function Module(file) { this.filename = file; this.exports = {}; this.paths = [] }
Module._nodeModulePaths = function() { return [] }
Module.prototype._compile = function(src, file) { new Function("module", "exports", "require", src)(this, this.exports, require) }
var fs = {
  readFileSync: function(f, enc) {
    var v = enc ? __readText(f) : __readBytes(f)
    if (v === null) { var e = new Error("ENOENT: " + f); e.code = "ENOENT"; throw e }
    return v
  }
}
var path = {
  dirname: function(p) { var i = p.lastIndexOf("/"); return i <= 0 ? (i === 0 ? "/" : ".") : p.slice(0, i) },
  resolve: function(p) { return p }
}
function require(name) {
  if (name === "fs") return fs
  if (name === "path") return path
  if (name === "module") return Module
  throw new Error("owl-walk has no module " + name)
}
""")

let walk = try! String(contentsOfFile: args[1], encoding: .utf8)
ctx.evaluateScript("(function(require) {\n" + walk + "\n})(require)", withSourceURL: URL(fileURLWithPath: args[1]))
exit(failed ? 1 : 0)
