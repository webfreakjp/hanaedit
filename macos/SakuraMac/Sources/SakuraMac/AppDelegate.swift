import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private var controllers: [EditorWindowController] = []
    private lazy var grepWindowController = GrepWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        openCommandLineFiles()

        if controllers.isEmpty {
            newDocument(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for filename in filenames {
            openFile(URL(fileURLWithPath: filename))
        }
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func newDocument(_ sender: Any?) {
        showEditor(url: nil)
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            for url in panel.urls {
                openFile(url)
            }
        }
    }

    @objc func saveDocument(_ sender: Any?) {
        activeEditor()?.saveDocument(sender)
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        activeEditor()?.saveDocumentAs(sender)
    }

    @objc func toggleLineNumbers(_ sender: Any?) {
        activeEditor()?.toggleLineNumbers(sender)
    }

    @objc func showFindPanel(_ sender: Any?) {
        activeEditor()?.showFindPanel(sender)
    }

    @objc func showReplacePanel(_ sender: Any?) {
        activeEditor()?.showReplacePanel(sender)
    }

    @objc func showGrepWindow(_ sender: Any?) {
        grepWindowController.showWindow(nil)
        grepWindowController.window?.makeKeyAndOrderFront(nil)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(saveDocument(_:)),
             #selector(saveDocumentAs(_:)),
             #selector(toggleLineNumbers(_:)),
             #selector(showFindPanel(_:)),
             #selector(showReplacePanel(_:)):
            return activeEditor() != nil
        default:
            return true
        }
    }

    private func openCommandLineFiles() {
        let arguments = CommandLine.arguments.dropFirst()

        for argument in arguments where !argument.hasPrefix("-") {
            openFile(URL(fileURLWithPath: argument))
        }
    }

    private func openFile(_ url: URL) {
        showEditor(url: url)
    }

    private func showEditor(url: URL?) {
        let controller = EditorWindowController(url: url)
        controllers.append(controller)
        controller.onClose = { [weak self, weak controller] in
            guard let controller else { return }
            self?.controllers.removeAll { $0 === controller }
        }
        controller.showWindow(nil)
    }

    private func activeEditor() -> EditorWindowController? {
        NSApp.keyWindow?.windowController as? EditorWindowController
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu(title: "Main Menu")
        NSApp.mainMenu = mainMenu

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu(title: "SakuraMac")
        appMenuItem.submenu = appMenu
        appMenu.addItem(
            withTitle: "Quit SakuraMac",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        let newItem = fileMenu.addItem(withTitle: "New", action: #selector(newDocument(_:)), keyEquivalent: "n")
        newItem.target = self

        let openItem = fileMenu.addItem(withTitle: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self

        fileMenu.addItem(NSMenuItem.separator())
        let saveItem = fileMenu.addItem(withTitle: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
        saveItem.target = self

        let saveAs = NSMenuItem(title: "Save As...", action: #selector(saveDocumentAs(_:)), keyEquivalent: "S")
        saveAs.keyEquivalentModifierMask = [.command, .shift]
        saveAs.target = self
        fileMenu.addItem(saveAs)
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")

        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redo)

        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(NSMenuItem.separator())
        let findItem = editMenu.addItem(withTitle: "Find...", action: #selector(showFindPanel(_:)), keyEquivalent: "f")
        findItem.target = self

        let replaceItem = NSMenuItem(title: "Replace...", action: #selector(showReplacePanel(_:)), keyEquivalent: "F")
        replaceItem.keyEquivalentModifierMask = [.command, .shift]
        replaceItem.target = self
        editMenu.addItem(replaceItem)

        let grepItem = NSMenuItem(title: "Grep in Directory...", action: #selector(showGrepWindow(_:)), keyEquivalent: "G")
        grepItem.keyEquivalentModifierMask = [.command]
        grepItem.target = self
        editMenu.addItem(grepItem)

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        let lineNumberItem = viewMenu.addItem(
            withTitle: "Toggle Line Numbers",
            action: #selector(toggleLineNumbers(_:)),
            keyEquivalent: "l"
        )
        lineNumberItem.target = self
    }
}
