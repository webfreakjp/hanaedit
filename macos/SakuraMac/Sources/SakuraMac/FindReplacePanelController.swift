import AppKit

final class FindReplacePanelController: NSWindowController {
    private weak var editor: EditorWindowController?
    private let findField = NSTextField()
    private let replaceField = NSTextField()
    private let regexButton = NSButton(checkboxWithTitle: "Regular expression", target: nil, action: nil)
    private let caseButton = NSButton(checkboxWithTitle: "Case sensitive", target: nil, action: nil)
    private let messageLabel = NSTextField(labelWithString: "")

    init(editor: EditorWindowController) {
        self.editor = editor

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 210),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Find and Replace"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false

        super.init(window: panel)

        configureContent()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(focusReplacement: Bool) {
        guard let window else { return }
        window.center()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(focusReplacement ? replaceField : findField)
    }

    private func configureContent() {
        guard let window else { return }

        findField.placeholderString = "Find"
        replaceField.placeholderString = "Replace"

        let findLabel = NSTextField(labelWithString: "Find")
        let replaceLabel = NSTextField(labelWithString: "Replace")

        let form = NSGridView(views: [
            [findLabel, findField],
            [replaceLabel, replaceField]
        ])
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 1).width = 330
        form.rowSpacing = 8

        let options = NSStackView(views: [regexButton, caseButton])
        options.orientation = .horizontal
        options.spacing = 16

        let findNextButton = NSButton(title: "Find Next", target: self, action: #selector(findNext(_:)))
        let findPreviousButton = NSButton(title: "Find Previous", target: self, action: #selector(findPrevious(_:)))
        let replaceButton = NSButton(title: "Replace", target: self, action: #selector(replace(_:)))
        let replaceAllButton = NSButton(title: "Replace All", target: self, action: #selector(replaceAll(_:)))

        let buttons = NSStackView(views: [findPreviousButton, findNextButton, replaceButton, replaceAllButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .trailing

        messageLabel.textColor = .secondaryLabelColor
        messageLabel.lineBreakMode = .byTruncatingMiddle

        let content = NSStackView(views: [form, options, buttons, messageLabel])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 12
        content.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        content.translatesAutoresizingMaskIntoConstraints = false

        window.contentView = content

        NSLayoutConstraint.activate([
            content.widthAnchor.constraint(equalToConstant: 428)
        ])
    }

    @objc private func findNext(_ sender: Any?) {
        find(backwards: false)
    }

    @objc private func findPrevious(_ sender: Any?) {
        find(backwards: true)
    }

    @objc private func replace(_ sender: Any?) {
        do {
            let replaced = try editor?.replaceCurrentMatch(
                options: currentOptions(),
                replacement: replaceField.stringValue
            ) ?? false
            messageLabel.stringValue = replaced ? "Replaced current match." : "No selected match to replace."
        } catch {
            messageLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func replaceAll(_ sender: Any?) {
        do {
            let count = try editor?.replaceAllMatches(
                options: currentOptions(),
                replacement: replaceField.stringValue
            ) ?? 0
            messageLabel.stringValue = "Replaced \(count) match(es)."
        } catch {
            messageLabel.stringValue = error.localizedDescription
        }
    }

    private func find(backwards: Bool) {
        do {
            let found = try editor?.findMatch(options: currentOptions(), backwards: backwards) ?? false
            messageLabel.stringValue = found ? "" : "No matches."
        } catch {
            messageLabel.stringValue = error.localizedDescription
        }
    }

    private func currentOptions() -> SearchOptions {
        SearchOptions(
            pattern: findField.stringValue,
            isRegularExpression: regexButton.state == .on,
            isCaseSensitive: caseButton.state == .on
        )
    }
}
