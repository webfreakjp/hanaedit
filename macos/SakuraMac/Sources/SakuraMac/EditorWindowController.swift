import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    var onClose: (() -> Void)?

    private let textView = RectangularTextView()
    private let scrollView = NSScrollView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var lineNumberRuler: LineNumberRulerView?
    private var documentURL: URL?
    private var fileEncoding: TextFileEncoding = .utf8
    private var lineEnding: LineEnding = .lf
    private var isEdited = false
    private lazy var findReplacePanelController = FindReplacePanelController(editor: self)

    init(url: URL?) {
        self.documentURL = url

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.delegate = self
        window.title = "Untitled"
        window.center()

        configureContent()

        if let url {
            load(url: url)
        } else {
            refreshTitle()
            refreshStatus()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc func saveDocument(_ sender: Any?) {
        if let documentURL {
            write(to: documentURL)
        } else {
            saveDocumentAs(sender)
        }
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = documentURL?.lastPathComponent ?? "Untitled.txt"

        if panel.runModal() == .OK, let url = panel.url {
            documentURL = url
            write(to: url)
        }
    }

    @objc func toggleLineNumbers(_ sender: Any?) {
        scrollView.hasVerticalRuler.toggle()
        scrollView.rulersVisible = scrollView.hasVerticalRuler
    }

    @objc func showFindPanel(_ sender: Any?) {
        findReplacePanelController.show(focusReplacement: false)
    }

    @objc func showReplacePanel(_ sender: Any?) {
        findReplacePanelController.show(focusReplacement: true)
    }

    func findMatch(options: SearchOptions, backwards: Bool) throws -> Bool {
        let nsText = textView.string as NSString
        guard nsText.length > 0 else { return false }

        let selectedRange = textView.selectedRange()
        let startLocation = backwards ? selectedRange.location : NSMaxRange(selectedRange)

        if let match = try SearchEngine.nextMatch(
            in: textView.string,
            options: options,
            startLocation: startLocation,
            backwards: backwards
        ) ?? SearchEngine.nextMatch(
            in: textView.string,
            options: options,
            startLocation: backwards ? nsText.length : 0,
            backwards: backwards
        ) {
            textView.setSelectedRange(match.range)
            textView.scrollRangeToVisible(match.range)
            window?.makeFirstResponder(textView)
            return true
        }

        NSSound.beep()
        return false
    }

    func replaceCurrentMatch(options: SearchOptions, replacement: String) throws -> Bool {
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else {
            _ = try findMatch(options: options, backwards: false)
            return false
        }

        guard let replacementText = try SearchEngine.replacement(
            for: textView.string,
            range: selectedRange,
            replacement: replacement,
            options: options
        ) else {
            _ = try findMatch(options: options, backwards: false)
            return false
        }

        replaceText(in: selectedRange, with: replacementText)
        textView.setSelectedRange(NSRange(location: selectedRange.location, length: (replacementText as NSString).length))
        textView.scrollRangeToVisible(textView.selectedRange())
        return true
    }

    func replaceAllMatches(options: SearchOptions, replacement: String) throws -> Int {
        let result = try SearchEngine.replacingAll(
            in: textView.string,
            replacement: replacement,
            options: options
        )

        guard result.count > 0 else {
            NSSound.beep()
            return 0
        }

        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        replaceText(in: fullRange, with: result.text)
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        return result.count
    }

    func textDidChange(_ notification: Notification) {
        isEdited = true
        refreshTitle()
        refreshStatus()
        lineNumberRuler?.needsDisplay = true
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        refreshStatus()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard isEdited else { return true }

        let alert = NSAlert()
        alert.messageText = "Save changes before closing?"
        alert.informativeText = documentURL?.lastPathComponent ?? "Untitled"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveDocument(nil)
            return !isEdited
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private func configureContent() {
        guard let window else { return }

        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.delegate = self
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false
        textView.textContainerInset = NSSize(width: 6, height: 8)

        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.documentView = textView

        let ruler = LineNumberRulerView(textView: textView)
        lineNumberRuler = ruler
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(visibleRectDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(scrollView)
        container.addSubview(statusLabel)
        window.contentView = container

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            statusLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    @objc private func visibleRectDidChange(_ notification: Notification) {
        lineNumberRuler?.needsDisplay = true
    }

    private func load(url: URL) {
        do {
            let result = try TextFile.read(from: url)
            textView.string = result.text
            fileEncoding = result.encoding
            lineEnding = result.lineEnding
            isEdited = false
            refreshTitle()
            refreshStatus()
        } catch {
            presentError(error)
        }
    }

    private func write(to url: URL) {
        do {
            try TextFile.write(
                textView.string,
                to: url,
                encoding: fileEncoding,
                lineEnding: lineEnding
            )
            isEdited = false
            refreshTitle()
            refreshStatus()
        } catch {
            presentError(error)
        }
    }

    private func refreshTitle() {
        let name = documentURL?.lastPathComponent ?? "Untitled"
        window?.title = isEdited ? "\(name) - Edited" : name
        window?.representedURL = documentURL
        window?.isDocumentEdited = isEdited
    }

    private func refreshStatus() {
        let selectedRange = textView.selectedRange()
        let position = TextPosition.position(in: textView.string, utf16Offset: selectedRange.location)
        let selectedLength = textView.selectedRanges.reduce(0) { partial, value in
            partial + value.rangeValue.length
        }
        let modified = isEdited ? "modified" : "saved"

        statusLabel.stringValue = [
            "\(fileEncoding.displayName)",
            "\(lineEnding.displayName)",
            "line \(position.line), column \(position.column)",
            selectedLength > 0 ? "selected \(selectedLength)" : nil,
            modified
        ].compactMap { $0 }.joined(separator: "  |  ")
    }

    private func replaceText(in range: NSRange, with replacement: String) {
        guard textView.shouldChangeText(in: range, replacementString: replacement) else { return }
        textView.textStorage?.replaceCharacters(in: range, with: replacement)
        textView.didChangeText()
    }

}
