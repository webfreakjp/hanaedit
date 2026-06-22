import Foundation

enum TextFileEncoding: CaseIterable {
    case utf8
    case utf8BOM
    case utf16LittleEndian
    case utf16BigEndian
    case shiftJIS
    case japaneseEUC
    case iso2022JP

    var displayName: String {
        switch self {
        case .utf8:
            return "UTF-8"
        case .utf8BOM:
            return "UTF-8 BOM"
        case .utf16LittleEndian:
            return "UTF-16 LE"
        case .utf16BigEndian:
            return "UTF-16 BE"
        case .shiftJIS:
            return "Shift_JIS"
        case .japaneseEUC:
            return "EUC-JP"
        case .iso2022JP:
            return "ISO-2022-JP"
        }
    }

    var stringEncoding: String.Encoding {
        switch self {
        case .utf8, .utf8BOM:
            return .utf8
        case .utf16LittleEndian:
            return .utf16LittleEndian
        case .utf16BigEndian:
            return .utf16BigEndian
        case .shiftJIS:
            return .shiftJIS
        case .japaneseEUC:
            return .japaneseEUC
        case .iso2022JP:
            return .iso2022JP
        }
    }
}

enum LineEnding {
    case lf
    case crlf
    case cr

    var displayName: String {
        switch self {
        case .lf:
            return "LF"
        case .crlf:
            return "CRLF"
        case .cr:
            return "CR"
        }
    }

    var rawValue: String {
        switch self {
        case .lf:
            return "\n"
        case .crlf:
            return "\r\n"
        case .cr:
            return "\r"
        }
    }
}

struct TextFile {
    struct ReadResult {
        let text: String
        let encoding: TextFileEncoding
        let lineEnding: LineEnding
    }

    static func read(from url: URL) throws -> ReadResult {
        let data = try Data(contentsOf: url)
        let decoded = decode(data)
        return ReadResult(
            text: decoded.text,
            encoding: decoded.encoding,
            lineEnding: detectLineEnding(decoded.text)
        )
    }

    static func write(
        _ text: String,
        to url: URL,
        encoding: TextFileEncoding,
        lineEnding: LineEnding
    ) throws {
        let normalizedText = normalizeLineEndings(text, to: lineEnding)
        guard var data = normalizedText.data(using: encoding.stringEncoding) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }

        if encoding == .utf8BOM {
            var withBOM = Data([0xEF, 0xBB, 0xBF])
            withBOM.append(data)
            data = withBOM
        }

        try data.write(to: url, options: .atomic)
    }

    private static func decode(_ data: Data) -> (text: String, encoding: TextFileEncoding) {
        if starts(data, with: [0xEF, 0xBB, 0xBF]),
           let text = String(data: Data(data.dropFirst(3)), encoding: .utf8) {
            return (text, .utf8BOM)
        }

        if starts(data, with: [0xFF, 0xFE]),
           let text = String(data: Data(data.dropFirst(2)), encoding: .utf16LittleEndian) {
            return (text, .utf16LittleEndian)
        }

        if starts(data, with: [0xFE, 0xFF]),
           let text = String(data: Data(data.dropFirst(2)), encoding: .utf16BigEndian) {
            return (text, .utf16BigEndian)
        }

        for encoding in TextFileEncoding.allCases where encoding != .utf8BOM {
            if let text = String(data: data, encoding: encoding.stringEncoding) {
                return (text, encoding)
            }
        }

        let fallback = String(decoding: data, as: UTF8.self)
        return (fallback, .utf8)
    }

    private static func detectLineEnding(_ text: String) -> LineEnding {
        var lfCount = 0
        var crlfCount = 0
        var crCount = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character == "\r" {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "\n" {
                    crlfCount += 1
                    index = text.index(after: next)
                    continue
                }
                crCount += 1
            } else if character == "\n" {
                lfCount += 1
            }

            index = text.index(after: index)
        }

        if crlfCount >= lfCount && crlfCount >= crCount && crlfCount > 0 {
            return .crlf
        }
        if crCount >= lfCount && crCount > 0 {
            return .cr
        }
        return .lf
    }

    private static func normalizeLineEndings(_ text: String, to lineEnding: LineEnding) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: lineEnding.rawValue)
    }

    private static func starts(_ data: Data, with bytes: [UInt8]) -> Bool {
        guard data.count >= bytes.count else { return false }
        return data.prefix(bytes.count).elementsEqual(bytes)
    }
}
