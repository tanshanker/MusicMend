import Foundation

struct FileScanner {
    static let defaultMusicPath: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Music")
            .appendingPathComponent("Music")
            .appendingPathComponent("Media.localized")
    }()

    static func scanDirectory(_ url: URL) throws -> [URL] {
        var mp3Files: [URL] = []

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ScanError.directoryNotFound(url.path)
        }

        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .nameKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            throw ScanError.cannotEnumerate(url.path)
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "mp3" {
                mp3Files.append(fileURL)
            }
        }

        return mp3Files.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }


}

enum ScanError: LocalizedError {
    case directoryNotFound(String)
    case cannotEnumerate(String)

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .cannotEnumerate(let path):
            return "Cannot read directory: \(path)"
        }
    }
}
