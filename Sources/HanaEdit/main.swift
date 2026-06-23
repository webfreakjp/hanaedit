import AppKit

let arguments = CommandLine.arguments.dropFirst()

if arguments.contains("--version") {
    print("\(AppInfo.name) \(AppInfo.version)")
    exit(0)
}

if arguments.contains("--help") || arguments.contains("-h") {
    print(
        """
        \(AppInfo.name) \(AppInfo.version)

        Usage:
          \(AppInfo.commandName) [file]
          \(AppInfo.commandName) --version
          \(AppInfo.commandName) --help

        Options:
          --version   Print the version and exit.
          -h, --help  Print this help and exit.
        """
    )
    exit(0)
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
