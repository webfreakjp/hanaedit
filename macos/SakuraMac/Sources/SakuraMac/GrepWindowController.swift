import AppKit

final class GrepWindowController: NSWindowController {
    private let directoryField = NSTextField()
    private let patternField = NSTextField()
    private let excludeField = NSTextField()
    private let regexButton = NSButton(checkboxWithTitle: "Regular expression", target: nil, action: nil)
    private let caseButton = NSButton(checkboxWithTitle: "Case sensitive", target: nil, action: nil)
    private let resultView = NSTextView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let searchButton = NSButton(title: "Search", target: nil, action: nil)

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Grep in Directory"
        window.center()

        super.init(window: window)

        configureContent()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        if directoryField.stringValue.isEmpty {
            directoryField.stringValue = FileManager.default.currentDirectoryPath
        }
        super.showWindow(sender)
        window?.makeFirstResponder(patternField)
    }

    private func configureContent() {
        guard let window else { return }

        directoryField.placeholderString = "Directory"
        patternField.placeholderString = "Search pattern"
        excludeField.placeholderString = "Excluded patterns"
        excludeField.stringValue = GrepEngine.defaultExcludedPatterns.joined(separator: ", ")
        directoryField.target = self
        directoryField.action = #selector(search(_:))
        patternField.target = self
        patternField.action = #selector(search(_:))
        excludeField.target = self
        excludeField.action = #selector(search(_:))

        let browseButton = NSButton(title: "Browse...", target: self, action: #selector(browseDirectory(_:)))
        searchButton.target = self
        searchButton.action = #selector(search(_:))

        let directoryRow = NSStackView(views: [
            NSTextField(labelWithString: "Directory"),
            directoryField,
            browseButton
        ])
        directoryRow.orientation = .horizontal
        directoryRow.spacing = 8

        let patternRow = NSStackView(views: [
            NSTextField(labelWithString: "Pattern"),
            patternField,
            searchButton
        ])
        patternRow.orientation = .horizontal
        patternRow.spacing = 8

        let excludeRow = NSStackView(views: [
            NSTextField(labelWithString: "Exclude"),
            excludeField
        ])
        excludeRow.orientation = .horizontal
        excludeRow.spacing = 8

        directoryField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        patternField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        excludeField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let optionsRow = NSStackView(views: [regexButton, caseButton])
        optionsRow.orientation = .horizontal
        optionsRow.spacing = 16

        resultView.isEditable = false
        resultView.isRichText = false
        resultView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        resultView.textColor = .labelColor
        resultView.backgroundColor = .textBackgroundColor
        resultView.textContainerInset = NSSize(width: 6, height: 6)
        resultView.minSize = NSSize(width: 0, height: 0)
        resultView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        resultView.isVerticallyResizable = true
        resultView.isHorizontallyResizable = true
        resultView.autoresizingMask = [.width]
        resultView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        resultView.textContainer?.widthTracksTextView = false

        let resultScrollView = NSScrollView()
        resultScrollView.hasVerticalScroller = true
        resultScrollView.hasHorizontalScroller = true
        resultScrollView.autohidesScrollers = false
        resultScrollView.documentView = resultView
        resultScrollView.borderType = .bezelBorder

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingMiddle

        let content = NSStackView(views: [directoryRow, patternRow, excludeRow, optionsRow, resultScrollView, statusLabel])
        content.orientation = .vertical
        content.alignment = .width
        content.spacing = 10
        content.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        content.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        window.contentView = container

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            resultScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])
    }

    @objc private func browseDirectory(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            directoryField.stringValue = url.path
        }
    }

    @objc private func search(_ sender: Any?) {
        let directory = URL(fileURLWithPath: directoryField.stringValue)
        let options = SearchOptions(
            pattern: patternField.stringValue,
            isRegularExpression: regexButton.state == .on,
            isCaseSensitive: caseButton.state == .on
        )
        let excludedPatterns = parseExcludedPatterns()

        guard !options.pattern.isEmpty else {
            resultView.string = ""
            statusLabel.stringValue = "Enter a search pattern."
            return
        }

        statusLabel.stringValue = "Searching..."
        resultView.string = ""
        searchButton.isEnabled = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let matches = try GrepEngine.search(
                    directory: directory,
                    options: options,
                    excludedPatterns: excludedPatterns
                )

                DispatchQueue.main.async {
                    self?.show(matches: matches, root: directory)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.resultView.string = ""
                    self?.statusLabel.stringValue = error.localizedDescription
                    self?.searchButton.isEnabled = true
                }
            }
        }
    }

    private func show(matches: [GrepMatch], root: URL) {
        resultView.string = format(matches: matches, root: root)
        resultView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        statusLabel.stringValue = "\(matches.count) match(es)."
        searchButton.isEnabled = true
    }

    private func format(matches: [GrepMatch], root: URL) -> String {
        guard !matches.isEmpty else {
            return "No matches."
        }

        return matches.map { match in
            let path = relativePath(for: match.url, root: root)
            return "\(path):\(match.line):\(match.column): \(match.text)"
        }.joined(separator: "\n")
    }

    private func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path

        guard path.hasPrefix(rootPath) else {
            return path
        }

        let relative = path.dropFirst(rootPath.count).drop { $0 == "/" }
        return relative.isEmpty ? url.lastPathComponent : String(relative)
    }

    private func parseExcludedPatterns() -> [String] {
        excludeField.stringValue
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
