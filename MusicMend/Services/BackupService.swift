import Foundation

struct BackupService {
    private static let backupDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".musicmend-backups")
    }()

    static func createBackup(for fileURL: URL) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")

        let backupDir = backupDirectory
            .appendingPathComponent(timestamp)

        try FileManager.default.createDirectory(
            at: backupDir,
            withIntermediateDirectories: true
        )

        let backupURL = backupDir.appendingPathComponent(fileURL.lastPathComponent)
        try FileManager.default.copyItem(at: fileURL, to: backupURL)

        return backupURL
    }

    static func restoreBackup(from backupURL: URL, to originalURL: URL) throws {
        // Remove current file
        if FileManager.default.fileExists(atPath: originalURL.path) {
            try FileManager.default.removeItem(at: originalURL)
        }
        try FileManager.default.copyItem(at: backupURL, to: originalURL)
    }

    static func cleanOldBackups(olderThan days: Int = 30) throws {
        guard FileManager.default.fileExists(atPath: backupDirectory.path) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let contents = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        )

        for item in contents {
            let attributes = try FileManager.default.attributesOfItem(atPath: item.path)
            if let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoffDate {
                try FileManager.default.removeItem(at: item)
            }
        }
    }
}
