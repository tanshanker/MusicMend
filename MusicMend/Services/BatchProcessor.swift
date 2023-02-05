import Foundation

@MainActor
@Observable
class BatchProcessor {
    var isProcessing = false
    var totalCount = 0
    var completedCount = 0
    var currentTrackName = ""
    var errors: [(String, String)] = []
    var isCancelled = false

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    func cancel() {
        isCancelled = true
    }

    func processAll(
        tracks: [TrackItem],
        fetchLyrics: Bool = true,
        fetchArtwork: Bool = true,
        cleanMetadata: Bool = true
    ) async {
        isProcessing = true
        totalCount = tracks.count
        completedCount = 0
        errors = []
        isCancelled = false

        for track in tracks {
            if isCancelled { break }

            currentTrackName = track.metadata.displayTitle
            track.status = .processing

            do {
                var actions: [RepairAction] = []

                // Clean metadata
                if cleanMetadata {
                    let cleanActions = MetadataCleaner.suggestRepairs(
                        for: track.issues,
                        metadata: track.metadata,
                        fileURL: track.fileURL
                    )
                    actions.append(contentsOf: cleanActions)
                }

                // Fetch lyrics if missing
                if fetchLyrics && !track.metadata.hasLyrics {
                    if let title = track.metadata.title,
                       let artist = track.metadata.artist {
                        if let result = try await LRCLIBService.fetchLyrics(
                            title: title,
                            artist: artist,
                            album: track.metadata.album,
                            duration: track.metadata.duration
                        ) {
                            if let plain = result.plainLyrics {
                                actions.append(.embedLyrics(plain: plain, synced: result.syncedLyrics))
                            }
                        }
                    }
                }

                // Fetch artwork if missing
                if fetchArtwork && !track.metadata.hasArtwork {
                    if let artist = track.metadata.artist,
                       let album = track.metadata.album {
                        if let artworkData = try await CoverArtService.fetchArtwork(
                            artist: artist,
                            album: album
                        ) {
                            actions.append(.embedArtwork(artworkData))
                        }
                    }
                }

                // Split out rename actions (handled separately from ID3 writes)
                let renameActions = actions.compactMap { action -> (String, String)? in
                    if case .renameFile(let from, let to) = action { return (from, to) }
                    return nil
                }
                let id3Actions = actions.filter {
                    if case .renameFile = $0 { return false }
                    return true
                }

                // Apply ID3 tag changes
                if !id3Actions.isEmpty {
                    _ = try BackupService.createBackup(for: track.fileURL)
                    try ID3Service.writeMetadata(to: track.fileURL, actions: id3Actions)
                }

                // Apply file renames
                if let rename = renameActions.first {
                    let dir = track.fileURL.deletingLastPathComponent()
                    let newURL = dir.appendingPathComponent(rename.1)
                    if !FileManager.default.fileExists(atPath: newURL.path) {
                        try FileManager.default.moveItem(at: track.fileURL, to: newURL)
                    }
                }

                // Re-read metadata to update the track
                let currentURL = track.fileURL
                let updatedMetadata = try ID3Service.readMetadata(from: currentURL)
                track.metadata = updatedMetadata
                track.issues = MetadataCleaner.detectIssues(in: updatedMetadata, fileURL: currentURL)
                track.pendingActions = []

                track.status = .fixed
            } catch {
                track.status = .error
                track.errorMessage = error.localizedDescription
                errors.append((track.fileName, error.localizedDescription))
            }

            completedCount += 1
        }

        currentTrackName = ""
        isProcessing = false
    }
}
