import AppKit

final class RectangularTextView: NSTextView {
    private struct RectangularPoint {
        var line: Int
        var column: Int
    }

    private var rectangularAnchor: RectangularPoint?
    private var rectangularCurrent: RectangularPoint?
    private var rectangularMarkedText: String?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            window?.makeFirstResponder(self)
            let point = rectangularPoint(for: characterOffset(for: event))
            rectangularAnchor = point
            rectangularCurrent = point
            updateRectangularSelection()
            return
        }

        clearRectangularSelection()
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard rectangularAnchor != nil else {
            super.mouseDragged(with: event)
            return
        }

        rectangularCurrent = rectangularPoint(for: characterOffset(for: event))
        updateRectangularSelection()
    }

    override func mouseUp(with event: NSEvent) {
        guard rectangularAnchor != nil else {
            super.mouseUp(with: event)
            return
        }
    }

    override func keyDown(with event: NSEvent) {
        if isEscape(event) {
            cancelRectangularSelection()
            return
        }

        if let direction = arrowDirection(for: event) {
            if rectangularAnchor != nil {
                moveRectangularCursor(direction)
                return
            }

            if event.modifierFlags.contains(.option) {
                beginRectangularSelection()
                moveRectangularCursor(direction)
                return
            }
        }

        super.keyDown(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        guard rectangularAnchor != nil, let text = stringValue(from: insertString), !text.isEmpty else {
            super.insertText(insertString, replacementRange: replacementRange)
            return
        }

        rectangularMarkedText = nil
        insert(text, intoRectangularSelectionAdvancingBy: (text as NSString).length)
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        guard rectangularAnchor != nil else {
            super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
            return
        }

        rectangularMarkedText = stringValue(from: string)
    }

    override func unmarkText() {
        guard rectangularAnchor != nil else {
            super.unmarkText()
            return
        }

        rectangularMarkedText = nil
    }

    override func hasMarkedText() -> Bool {
        guard rectangularAnchor != nil else {
            return super.hasMarkedText()
        }

        return rectangularMarkedText?.isEmpty == false
    }

    override func markedRange() -> NSRange {
        guard rectangularAnchor != nil else {
            return super.markedRange()
        }

        if rectangularMarkedText?.isEmpty == false {
            return selectedRange()
        }

        return NSRange(location: NSNotFound, length: 0)
    }

    override func paste(_ sender: Any?) {
        guard rectangularAnchor != nil, let text = NSPasteboard.general.string(forType: .string) else {
            super.paste(sender)
            return
        }

        insert(text, intoRectangularSelectionAdvancingBy: (text as NSString).length)
    }

    override func deleteBackward(_ sender: Any?) {
        guard rectangularAnchor != nil else {
            super.deleteBackward(sender)
            return
        }

        deleteRectangularSelection(backwards: true)
    }

    override func deleteForward(_ sender: Any?) {
        guard rectangularAnchor != nil else {
            super.deleteForward(sender)
            return
        }

        deleteRectangularSelection(backwards: false)
    }

    private func characterOffset(for event: NSEvent) -> Int {
        let point = convert(event.locationInWindow, from: nil)
        let offset = characterIndexForInsertion(at: point)
        return min(max(0, offset), (string as NSString).length)
    }

    private func beginRectangularSelection() {
        let point = rectangularPoint(for: selectedRange().location)
        rectangularAnchor = point
        rectangularCurrent = point
        updateRectangularSelection()
    }

    private func cancelRectangularSelection() {
        guard let current = rectangularCurrent else { return }
        let offset = offset(for: current)
        clearRectangularSelection()
        setSelectedRange(NSRange(location: offset, length: 0))
    }

    private func clearRectangularSelection() {
        rectangularAnchor = nil
        rectangularCurrent = nil
        rectangularMarkedText = nil
    }

    private func updateRectangularSelection() {
        let ranges = rectangularRanges()
        selectedRanges = ranges.map { NSValue(range: $0) }

        if let current = rectangularCurrent {
            scrollRangeToVisible(NSRange(location: offset(for: current), length: 0))
        }
    }

    private func insert(_ insertedText: String, intoRectangularSelectionAdvancingBy columnDelta: Int) {
        guard let rectangle = currentRectangle() else { return }
        let targets = lineIndexes(for: rectangle).map { lineIndex in
            insertionTarget(line: lineIndex, column: rectangle.leftColumn)
        }

        guard !targets.isEmpty else { return }

        if shouldChangeText(in: NSRange(location: targets[0].location, length: 0), replacementString: insertedText) {
            textStorage?.beginEditing()
            for target in targets.reversed() {
                let replacement = String(repeating: " ", count: target.padding) + insertedText
                textStorage?.replaceCharacters(in: NSRange(location: target.location, length: 0), with: replacement)
            }
            textStorage?.endEditing()
            didChangeText()
        }

        advanceRectangularSelection(toColumn: rectangle.leftColumn + columnDelta, rectangle: rectangle)
    }

    private func deleteRectangularSelection(backwards: Bool) {
        guard let rectangle = currentRectangle() else { return }
        let ranges = lineIndexes(for: rectangle)
            .compactMap { deletionRange(line: $0, rectangle: rectangle, backwards: backwards) }

        guard !ranges.isEmpty else {
            NSSound.beep()
            return
        }

        if shouldChangeText(in: ranges[0], replacementString: "") {
            textStorage?.beginEditing()
            for range in ranges.reversed() {
                textStorage?.replaceCharacters(in: range, with: "")
            }
            textStorage?.endEditing()
            didChangeText()
        }

        let nextColumn = rectangle.hasWidth ? rectangle.leftColumn : max(0, rectangle.leftColumn - (backwards ? 1 : 0))
        advanceRectangularSelection(toColumn: nextColumn, rectangle: rectangle)
    }

    private func advanceRectangularSelection(toColumn column: Int, rectangle: RectangularRectangle) {
        guard let anchor = rectangularAnchor, let current = rectangularCurrent else { return }
        rectangularAnchor = RectangularPoint(line: anchor.line, column: column)
        rectangularCurrent = RectangularPoint(line: current.line, column: column)
        updateRectangularSelection()
    }

    private func rectangularRanges() -> [NSRange] {
        guard let rectangle = currentRectangle() else { return [] }
        return lineIndexes(for: rectangle).map { rangeForLine($0, rectangle: rectangle) }
    }

    private struct RectangularRectangle {
        let firstLine: Int
        let lastLine: Int
        let leftColumn: Int
        let rightColumn: Int

        var hasWidth: Bool {
            rightColumn > leftColumn
        }
    }

    private func currentRectangle() -> RectangularRectangle? {
        guard let anchor = rectangularAnchor, let current = rectangularCurrent else {
            return nil
        }

        return RectangularRectangle(
            firstLine: min(anchor.line, current.line),
            lastLine: max(anchor.line, current.line),
            leftColumn: min(anchor.column, current.column),
            rightColumn: max(anchor.column, current.column)
        )
    }

    private func lineIndexes(for rectangle: RectangularRectangle) -> [Int] {
        Array(rectangle.firstLine...rectangle.lastLine)
    }

    private func rangeForLine(_ line: Int, rectangle: RectangularRectangle) -> NSRange {
        let nsText = string as NSString
        let lineRange = lineRange(for: line, in: nsText)
        let contentLength = lineContentLength(for: lineRange, in: nsText)
        let location = lineRange.location + min(rectangle.leftColumn, contentLength)
        let endLocation = lineRange.location + min(rectangle.rightColumn, contentLength)
        return NSRange(location: location, length: max(0, endLocation - location))
    }

    private func insertionTarget(line: Int, column: Int) -> (location: Int, padding: Int) {
        let nsText = string as NSString
        let lineRange = lineRange(for: line, in: nsText)
        let contentLength = lineContentLength(for: lineRange, in: nsText)
        return (
            location: lineRange.location + min(column, contentLength),
            padding: max(0, column - contentLength)
        )
    }

    private func deletionRange(
        line: Int,
        rectangle: RectangularRectangle,
        backwards: Bool
    ) -> NSRange? {
        let nsText = string as NSString
        let lineRange = lineRange(for: line, in: nsText)
        let contentLength = lineContentLength(for: lineRange, in: nsText)
        let lineStart = lineRange.location
        let lineEnd = lineRange.location + contentLength

        if rectangle.hasWidth {
            let location = lineStart + min(rectangle.leftColumn, contentLength)
            let endLocation = lineStart + min(rectangle.rightColumn, contentLength)
            guard endLocation > location else { return nil }
            return NSRange(location: location, length: endLocation - location)
        }

        if backwards {
            let endLocation = lineStart + min(rectangle.leftColumn, contentLength)
            guard endLocation > lineStart else { return nil }
            return NSRange(location: endLocation - 1, length: 1)
        }

        let location = lineStart + min(rectangle.leftColumn, contentLength)
        guard location < lineEnd else { return nil }
        return NSRange(location: location, length: 1)
    }

    private func moveRectangularCursor(_ direction: RectangularDirection) {
        guard var current = rectangularCurrent else { return }
        let lineCount = max(1, lineCount())

        switch direction {
        case .left:
            current.column = max(0, current.column - 1)
        case .right:
            current.column += 1
        case .up:
            current.line = max(0, current.line - 1)
        case .down:
            current.line = min(lineCount - 1, current.line + 1)
        }

        rectangularCurrent = current
        updateRectangularSelection()
    }

    private enum RectangularDirection {
        case left
        case right
        case up
        case down
    }

    private func arrowDirection(for event: NSEvent) -> RectangularDirection? {
        switch event.keyCode {
        case 123:
            return .left
        case 124:
            return .right
        case 125:
            return .down
        case 126:
            return .up
        default:
            return nil
        }
    }

    private func isEscape(_ event: NSEvent) -> Bool {
        event.keyCode == 53
    }

    private func stringValue(from insertString: Any) -> String? {
        if let string = insertString as? String {
            return string
        }
        if let attributedString = insertString as? NSAttributedString {
            return attributedString.string
        }
        return nil
    }

    private func rectangularPoint(for offset: Int) -> RectangularPoint {
        let nsText = string as NSString
        let location = min(max(0, offset), nsText.length)
        let lineRange = nsText.lineRange(for: NSRange(location: location, length: 0))
        return RectangularPoint(
            line: lineIndex(forLineStart: lineRange.location, in: nsText),
            column: location - lineRange.location
        )
    }

    private func offset(for point: RectangularPoint) -> Int {
        let nsText = string as NSString
        let lineRange = lineRange(for: point.line, in: nsText)
        let contentLength = lineContentLength(for: lineRange, in: nsText)
        return lineRange.location + min(point.column, contentLength)
    }

    private func lineCount() -> Int {
        let nsText = string as NSString
        guard nsText.length > 0 else { return 1 }

        var count = 0
        var location = 0
        while location < nsText.length {
            let range = nsText.lineRange(for: NSRange(location: location, length: 0))
            count += 1
            let next = NSMaxRange(range)
            if next <= location {
                break
            }
            location = next
        }

        if nsText.substring(from: nsText.length - 1) == "\n" {
            count += 1
        }

        return count
    }

    private func lineIndex(forLineStart targetLineStart: Int, in text: NSString) -> Int {
        var index = 0
        var lineStart = 0

        while lineStart < targetLineStart {
            let range = text.lineRange(for: NSRange(location: lineStart, length: 0))
            let next = NSMaxRange(range)
            if next <= lineStart {
                break
            }
            lineStart = next
            index += 1
        }

        return index
    }

    private func lineRange(for lineIndex: Int, in text: NSString) -> NSRange {
        guard text.length > 0 else {
            return NSRange(location: 0, length: 0)
        }

        var currentLine = 0
        var location = 0
        var lastRange = NSRange(location: 0, length: 0)

        while location < text.length {
            let range = text.lineRange(for: NSRange(location: location, length: 0))
            lastRange = range
            if currentLine == lineIndex {
                return range
            }

            let next = NSMaxRange(range)
            if next <= location {
                break
            }

            location = next
            currentLine += 1
        }

        if lineIndex == currentLine {
            return NSRange(location: text.length, length: 0)
        }

        return lastRange
    }

    private func lineContentLength(for lineRange: NSRange, in text: NSString) -> Int {
        var length = lineRange.length
        if length > 0, text.substring(with: NSRange(location: NSMaxRange(lineRange) - 1, length: 1)) == "\n" {
            length -= 1
        }
        if length > 0, text.substring(with: NSRange(location: lineRange.location + length - 1, length: 1)) == "\r" {
            length -= 1
        }
        return length
    }
}
