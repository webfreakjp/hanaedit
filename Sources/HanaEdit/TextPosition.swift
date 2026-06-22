import Foundation

struct TextPosition {
    let line: Int
    let column: Int

    static func position(in text: String, utf16Offset: Int) -> TextPosition {
        let offset = min(max(0, utf16Offset), text.utf16.count)
        var line = 1
        var column = 1
        var currentOffset = 0

        for scalar in text.unicodeScalars {
            if currentOffset >= offset {
                break
            }

            if scalar.value == 10 {
                line += 1
                column = 1
            } else {
                column += 1
            }

            currentOffset += scalar.utf16.count
        }

        return TextPosition(line: line, column: column)
    }
}
