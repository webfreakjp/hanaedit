import Foundation

struct SearchOptions {
    let pattern: String
    let isRegularExpression: Bool
    let isCaseSensitive: Bool
}

struct SearchMatch {
    let range: NSRange
}

enum SearchEngine {
    static func nextMatch(
        in text: String,
        options: SearchOptions,
        startLocation: Int,
        backwards: Bool
    ) throws -> SearchMatch? {
        guard !options.pattern.isEmpty else { return nil }

        if options.isRegularExpression {
            return try nextRegularExpressionMatch(
                in: text,
                options: options,
                startLocation: startLocation,
                backwards: backwards
            )
        }

        return nextLiteralMatch(
            in: text,
            options: options,
            startLocation: startLocation,
            backwards: backwards
        )
    }

    static func allMatches(in text: String, options: SearchOptions) throws -> [SearchMatch] {
        guard !options.pattern.isEmpty else { return [] }

        if options.isRegularExpression {
            let expression = try regularExpression(for: options)
            let nsText = text as NSString
            return expression
                .matches(in: text, range: NSRange(location: 0, length: nsText.length))
                .filter { $0.range.length > 0 }
                .map { SearchMatch(range: $0.range) }
        }

        var matches: [SearchMatch] = []
        let nsText = text as NSString
        var searchLocation = 0
        let findOptions = literalFindOptions(for: options)

        while searchLocation < nsText.length {
            let range = NSRange(location: searchLocation, length: nsText.length - searchLocation)
            let match = nsText.range(of: options.pattern, options: findOptions, range: range)

            if match.location == NSNotFound || match.length == 0 {
                break
            }

            matches.append(SearchMatch(range: match))
            searchLocation = NSMaxRange(match)
        }

        return matches
    }

    static func replacement(
        for text: String,
        range: NSRange,
        replacement: String,
        options: SearchOptions
    ) throws -> String? {
        guard !options.pattern.isEmpty else { return nil }
        let nsText = text as NSString
        guard NSMaxRange(range) <= nsText.length else { return nil }

        if options.isRegularExpression {
            let expression = try regularExpression(for: options)
            let template = regularExpressionReplacementTemplate(replacement)
            let selectedText = nsText.substring(with: range)
            let selectedRange = NSRange(location: 0, length: (selectedText as NSString).length)
            let matches = expression.matches(in: selectedText, range: selectedRange)

            guard matches.count == 1, matches[0].range == selectedRange else {
                return nil
            }

            return expression.replacementString(
                for: matches[0],
                in: selectedText,
                offset: 0,
                template: template
            )
        }

        let expandedReplacement = expandedLiteralReplacementString(replacement)
        let selectedText = nsText.substring(with: range) as NSString
        let findOptions = literalFindOptions(for: options)
        let fullRange = NSRange(location: 0, length: selectedText.length)
        let match = selectedText.range(of: options.pattern, options: findOptions, range: fullRange)

        guard match == fullRange else {
            return nil
        }

        return expandedReplacement
    }

    static func replacingAll(
        in text: String,
        replacement: String,
        options: SearchOptions
    ) throws -> (text: String, count: Int) {
        guard !options.pattern.isEmpty else {
            return (text, 0)
        }

        if options.isRegularExpression {
            let expression = try regularExpression(for: options)
            let template = regularExpressionReplacementTemplate(replacement)
            let nsText = text as NSString
            let range = NSRange(location: 0, length: nsText.length)
            let count = expression.numberOfMatches(in: text, range: range)
            let replaced = expression.stringByReplacingMatches(
                in: text,
                range: range,
                withTemplate: template
            )
            return (replaced, count)
        }

        let expandedReplacement = expandedLiteralReplacementString(replacement)
        let matches = try allMatches(in: text, options: options)
        guard !matches.isEmpty else {
            return (text, 0)
        }

        let result = NSMutableString(string: text)
        for match in matches.reversed() {
            result.replaceCharacters(in: match.range, with: expandedReplacement)
        }

        return (result as String, matches.count)
    }

    private static func expandedLiteralReplacementString(_ replacement: String) -> String {
        var result = ""
        var iterator = replacement.makeIterator()

        while let character = iterator.next() {
            guard character == "\\" else {
                result.append(character)
                continue
            }

            guard let escaped = iterator.next() else {
                result.append("\\")
                break
            }

            switch escaped {
            case "t":
                result.append("\t")
            case "n":
                result.append("\n")
            case "r":
                result.append("\r")
            case "\\":
                result.append("\\")
            default:
                result.append("\\")
                result.append(escaped)
            }
        }

        return result
    }

    private static func regularExpressionReplacementTemplate(_ replacement: String) -> String {
        var result = ""
        var iterator = replacement.makeIterator()

        while let character = iterator.next() {
            guard character == "\\" else {
                result.append(character)
                continue
            }

            guard let escaped = iterator.next() else {
                result.append("\\\\")
                break
            }

            switch escaped {
            case "t":
                result.append("\t")
            case "n":
                result.append("\n")
            case "r":
                result.append("\r")
            case "\\":
                result.append("\\\\")
            case "$":
                result.append("\\$")
            default:
                result.append("\\\\")
                result.append(escaped)
            }
        }

        return result
    }

    private static func nextLiteralMatch(
        in text: String,
        options: SearchOptions,
        startLocation: Int,
        backwards: Bool
    ) -> SearchMatch? {
        let nsText = text as NSString
        guard nsText.length > 0 else { return nil }

        let location = min(max(0, startLocation), nsText.length)
        let searchRange: NSRange
        if backwards {
            searchRange = NSRange(location: 0, length: location)
        } else {
            searchRange = NSRange(location: location, length: nsText.length - location)
        }

        guard searchRange.length > 0 else { return nil }

        var findOptions = literalFindOptions(for: options)
        if backwards {
            findOptions.insert(.backwards)
        }

        let match = nsText.range(of: options.pattern, options: findOptions, range: searchRange)
        guard match.location != NSNotFound, match.length > 0 else { return nil }
        return SearchMatch(range: match)
    }

    private static func nextRegularExpressionMatch(
        in text: String,
        options: SearchOptions,
        startLocation: Int,
        backwards: Bool
    ) throws -> SearchMatch? {
        let expression = try regularExpression(for: options)
        let nsText = text as NSString
        let location = min(max(0, startLocation), nsText.length)
        let range: NSRange

        if backwards {
            range = NSRange(location: 0, length: location)
            return expression
                .matches(in: text, range: range)
                .last { $0.range.length > 0 }
                .map { SearchMatch(range: $0.range) }
        }

        range = NSRange(location: location, length: nsText.length - location)
        return expression
            .firstMatch(in: text, range: range)
            .flatMap { $0.range.length > 0 ? SearchMatch(range: $0.range) : nil }
    }

    private static func regularExpression(for options: SearchOptions) throws -> NSRegularExpression {
        var regexOptions: NSRegularExpression.Options = []
        if !options.isCaseSensitive {
            regexOptions.insert(.caseInsensitive)
        }
        return try NSRegularExpression(pattern: options.pattern, options: regexOptions)
    }

    private static func literalFindOptions(for options: SearchOptions) -> NSString.CompareOptions {
        var findOptions: NSString.CompareOptions = []
        if !options.isCaseSensitive {
            findOptions.insert(.caseInsensitive)
        }
        return findOptions
    }
}
