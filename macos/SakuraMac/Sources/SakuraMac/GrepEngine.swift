import Darwin
import Foundation

struct GrepMatch {
    let url: URL
    let line: Int
    let column: Int
    let text: String
}

enum GrepEngine {
    static let defaultExcludedPatterns = [".git", ".build", "DerivedData", "node_modules"]

    static func search(
        directory: URL,
        options: SearchOptions,
        excludedPatterns: [String] = defaultExcludedPatterns
    ) throws -> [GrepMatch] {
        guard !options.pattern.isEmpty else { return [] }

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isHiddenKey],
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        var results: [GrepMatch] = []

        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
            if values?.isDirectory == true {
                if isExcluded(url: url, root: directory, patterns: excludedPatterns) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard values?.isRegularFile == true else {
                continue
            }
            guard !isExcluded(url: url, root: directory, patterns: excludedPatterns) else {
                continue
            }

            guard let text = try? TextFile.read(from: url).text else {
                continue
            }

            results.append(contentsOf: matches(in: text, url: url, options: options))
        }

        return results
    }

    private static func matches(in text: String, url: URL, options: SearchOptions) -> [GrepMatch] {
        let nsText = text as NSString
        let lines = text.components(separatedBy: .newlines)
        var matches: [GrepMatch] = []
        var lineStart = 0

        for (index, line) in lines.enumerated() {
            let lineRange = NSRange(location: lineStart, length: (line as NSString).length)
            if let lineMatches = try? SearchEngine.allMatches(in: line, options: options) {
                for match in lineMatches {
                    matches.append(
                        GrepMatch(
                            url: url,
                            line: index + 1,
                            column: match.range.location + 1,
                            text: line
                        )
                    )
                }
            }

            lineStart = NSMaxRange(lineRange)
            if lineStart < nsText.length {
                lineStart += 1
            }
        }

        return matches
    }

    private static func isExcluded(url: URL, root: URL, patterns: [String]) -> Bool {
        let normalizedPatterns = patterns
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedPatterns.isEmpty else {
            return false
        }

        let relativePath = relativePath(for: url, root: root)
        let candidates = [url.lastPathComponent, relativePath]

        return normalizedPatterns.contains { pattern in
            candidates.contains { candidate in
                fnmatch(pattern, candidate, 0) == 0
            }
        }
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path

        guard path.hasPrefix(rootPath) else {
            return path
        }

        let relative = path.dropFirst(rootPath.count).drop { $0 == "/" }
        return relative.isEmpty ? url.lastPathComponent : String(relative)
    }
}
