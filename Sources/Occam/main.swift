import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()

if let idx = CommandLine.arguments.firstIndex(of: "--screenshot"),
   idx + 1 < CommandLine.arguments.count {
    delegate.screenshotOutputPath = CommandLine.arguments[idx + 1]
}

if CommandLine.arguments.contains("--check-update") {
    delegate.checkUpdateMode = true
}

app.delegate = delegate
app.run()
