import Foundation

struct MetadataCleaner {
    static func detectIssues(in metadata: TrackMetadata, fileURL: URL? = nil) -> [MetadataIssue] {
        var issues: [MetadataIssue] = []

        // Missing fields
        if metadata.title == nil || metadata.title?.isEmpty == true {
            issues.append(.missingTitle)
        }
        if metadata.artist == nil || metadata.artist?.isEmpty == true {
            issues.append(.missingArtist)
        }
        if metadata.album == nil || metadata.album?.isEmpty == true {
            issues.append(.missingAlbum)
        }
        if !metadata.hasArtwork {
            issues.append(.missingArtwork)
        }
        if !metadata.hasLyrics {
            issues.append(.missingLyrics)
        }

        // Check string fields for problems
        let fieldsToCheck: [(String, String?)] = [
            ("title", metadata.title),
            ("artist", metadata.artist),
            ("album", metadata.album),
            ("albumArtist", metadata.albumArtist),
        ]

        for (fieldName, value) in fieldsToCheck {
            guard let text = value, !text.isEmpty else { continue }

            if StringCleaning.containsURL(text) {
                issues.append(.suspiciousURL(field: fieldName, value: text))
            }
            if StringCleaning.containsSpam(text) {
                issues.append(.spamText(field: fieldName, value: text))
            }
            if StringCleaning.hasEncodingArtifacts(text) {
                issues.append(.encodingArtifacts(field: fieldName, value: text))
            }
        }

        // Check filename for URLs/spam
        if let fileURL = fileURL {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            if StringCleaning.containsURL(filename) || StringCleaning.containsSpam(filename) {
                let cleaned = StringCleaning.cleanFilename(filename)
                if cleaned != filename && !cleaned.isEmpty {
                    issues.append(.filenameURL(originalName: filename, cleanedName: cleaned))
                }
            }
        }

        return issues
    }

    static func suggestRepairs(for issues: [MetadataIssue], metadata: TrackMetadata, fileURL: URL? = nil) -> [RepairAction] {
        var actions: [RepairAction] = []

        for issue in issues {
            switch issue {
            case .suspiciousURL(let field, let value),
                 .spamText(let field, let value),
                 .encodingArtifacts(let field, let value):
                let cleaned = StringCleaning.cleanString(value)
                if !cleaned.isEmpty && cleaned != value {
                    actions.append(.cleanField(field: field, original: value, cleaned: cleaned))
                }
            case .filenameURL(let originalName, let cleanedName):
                if let fileURL = fileURL {
                    let ext = fileURL.pathExtension
                    let originalFull = "\(originalName).\(ext)"
                    let cleanedFull = "\(cleanedName).\(ext)"
                    actions.append(.renameFile(from: originalFull, to: cleanedFull))
                }
            case .missingArtwork, .missingLyrics, .missingTitle, .missingArtist, .missingAlbum:
                break
            }
        }

        return actions
    }
}
