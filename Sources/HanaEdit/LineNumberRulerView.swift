import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    private let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.secondaryLabelColor
    ]

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 48
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var requiredThickness: CGFloat {
        guard let textView else { return 48 }
        let lineCount = max(1, textView.string.filter { $0 == "\n" }.count + 1)
        let digits = max(2, String(lineCount).count)
        return CGFloat(digits * 8 + 18)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard
            let textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return
        }

        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var lineNumber = lineNumberForCharacterOffset(characterRange.location, in: textView.string)
        var glyphIndex = glyphRange.location

        while glyphIndex < NSMaxRange(glyphRange) {
            var effectiveRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex,
                effectiveRange: &effectiveRange,
                withoutAdditionalLayout: true
            )

            draw(lineNumber: lineNumber, y: lineRect.minY + textView.textContainerInset.height - visibleRect.minY)

            let nextGlyphIndex = NSMaxRange(effectiveRange)
            if nextGlyphIndex <= glyphIndex {
                break
            }

            glyphIndex = nextGlyphIndex
            lineNumber += 1
        }
    }

    private func draw(lineNumber: Int, y: CGFloat) {
        let text = "\(lineNumber)" as NSString
        let size = text.size(withAttributes: textAttributes)
        let point = NSPoint(
            x: bounds.width - size.width - 6,
            y: y + 1
        )
        text.draw(at: point, withAttributes: textAttributes)
    }

    private func lineNumberForCharacterOffset(_ offset: Int, in text: String) -> Int {
        guard offset > 0 else { return 1 }

        let nsText = text as NSString
        let limitedOffset = min(offset, nsText.length)
        let prefix = nsText.substring(to: limitedOffset)
        return prefix.filter { $0 == "\n" }.count + 1
    }
}
