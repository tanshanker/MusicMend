import Foundation

struct StringCleaning {
    static let urlPattern = try! NSRegularExpression(
        pattern: #"https?://[^\s]+"#,
        options: .caseInsensitive
    )

    static let wwwPattern = try! NSRegularExpression(
        pattern: #"www\.[^\s]+"#,
        options: .caseInsensitive
    )

    static let spamPatterns: [NSRegularExpression] = {
        let patterns = [
            #"(?i)download(ed)?\s+(at|from|via)"#,
            #"(?i)free\s+mp3"#,
            #"(?i)ripped\s+by"#,
            #"(?i)uploaded\s+by"#,
            #"(?i)www\.\w+\.(com|net|org|io)"#,
            #"(?i)\[.*?(mp3|download|free|rip).*?\]"#,
            #"(?i)\(.*?(mp3|download|free|rip).*?\)"#,
            #"(?i)(mp3|music)\s*(skull|download|juice|clan)"#,
            #"(?i)tag(ged)?\s+by"#,
            #"(?i)converted\s+by"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    static let encodingArtifacts: [(broken: String, fixed: String)] = [
        ("\u{00C3}\u{00A9}", "e"), // e-acute mojibake
        ("\u{00C3}\u{00A8}", "e"), // e-grave mojibake
        ("\u{00C3}\u{00A0}", "a"), // a-grave mojibake
        ("\u{00C3}\u{00A2}", "a"), // a-circumflex mojibake
        ("\u{00C3}\u{00AE}", "i"), // i-circumflex mojibake
        ("\u{00C3}\u{00AF}", "i"), // i-diaeresis mojibake
        ("\u{00C3}\u{00B4}", "o"), // o-circumflex mojibake
        ("\u{00C3}\u{00B6}", "o"), // o-diaeresis mojibake
        ("\u{00C3}\u{00BC}", "u"), // u-diaeresis mojibake
        ("\u{00C3}\u{00B1}", "n"), // n-tilde mojibake
        ("\u{00C2}\u{00A0}", " "), // non-breaking space mojibake
        ("\u{00C2}\u{00A9}", "(c)"), // copyright mojibake
    ]

    static func containsURL(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return urlPattern.firstMatch(in: text, range: range) != nil
            || wwwPattern.firstMatch(in: text, range: range) != nil
    }

    static func containsSpam(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return spamPatterns.contains { regex in
            regex.firstMatch(in: text, range: range) != nil
        }
    }

    static func hasEncodingArtifacts(_ text: String) -> Bool {
        encodingArtifacts.contains { text.contains($0.broken) }
    }

    static func removeURLs(from text: String) -> String {
        var result = text
        let range = NSRange(result.startIndex..., in: result)
        result = urlPattern.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        let range2 = NSRange(result.startIndex..., in: result)
        result = wwwPattern.stringByReplacingMatches(in: result, range: range2, withTemplate: "")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func removeSpam(from text: String) -> String {
        var result = text
        for pattern in spamPatterns {
            let range = NSRange(result.startIndex..., in: result)
            result = pattern.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func fixEncoding(_ text: String) -> String {
        var result = text
        for artifact in encodingArtifacts {
            result = result.replacingOccurrences(of: artifact.broken, with: artifact.fixed)
        }
        return result
    }

    static func cleanString(_ text: String) -> String {
        var result = text
        result = removeURLs(from: result)
        result = removeSpam(from: result)
        result = fixEncoding(result)
        // Normalize whitespace
        result = result.replacingOccurrences(
            of: #"\s{2,}"#, with: " ",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func cleanFilename(_ filename: String) -> String {
        var result = filename
        result = removeURLs(from: result)
        result = removeSpam(from: result)
        result = fixEncoding(result)
        // Clean filename-specific junk: brackets/parens left empty after removal
        result = result.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[\s*\]"#, with: "", options: .regularExpression)
        // Remove leading/trailing dashes, underscores, dots, spaces
        result = result.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: #"^[\s\-_.]+|[\s\-_.]+$"#, with: "", options: .regularExpression)
        return result
    }
}
