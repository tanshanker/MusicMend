import Foundation

enum MetadataIssue: Identifiable, Hashable {
    case missingTitle
    case missingArtist
    case missingAlbum
    case missingArtwork
    case missingLyrics
    case suspiciousURL(field: String, value: String)
    case spamText(field: String, value: String)
    case encodingArtifacts(field: String, value: String)
    case filenameURL(originalName: String, cleanedName: String)

    var id: String {
        switch self {
        case .missingTitle: return "missing_title"
        case .missingArtist: return "missing_artist"
        case .missingAlbum: return "missing_album"
        case .missingArtwork: return "missing_artwork"
        case .missingLyrics: return "missing_lyrics"
        case .suspiciousURL(let field, _): return "url_\(field)"
        case .spamText(let field, _): return "spam_\(field)"
        case .encodingArtifacts(let field, _): return "encoding_\(field)"
        case .filenameURL: return "filename_url"
        }
    }

    var description: String {
        switch self {
        case .missingTitle: return "Missing title"
        case .missingArtist: return "Missing artist"
        case .missingAlbum: return "Missing album"
        case .missingArtwork: return "Missing album artwork"
        case .missingLyrics: return "Missing lyrics"
        case .suspiciousURL(let field, let value):
            return "URL found in \(field): \(value)"
        case .spamText(let field, let value):
            return "Spam text in \(field): \(value)"
        case .encodingArtifacts(let field, let value):
            return "Encoding issue in \(field): \(value)"
        case .filenameURL(let originalName, _):
            return "URL in filename: \(originalName)"
        }
    }

    var severity: IssueSeverity {
        switch self {
        case .suspiciousURL, .spamText, .encodingArtifacts, .filenameURL:
            return .warning
        case .missingArtwork, .missingLyrics:
            return .info
        case .missingTitle, .missingArtist, .missingAlbum:
            return .warning
        }
    }
}

enum IssueSeverity {
    case info
    case warning
}
