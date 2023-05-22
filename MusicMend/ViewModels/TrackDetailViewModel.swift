import Foundation

@MainActor
@Observable
class TrackDetailViewModel {
    var track: TrackItem?
    var isFetchingLyrics = false
    var isFetchingArtwork = false
    var lyricsError: String?
    var artworkError: String?
    var isSaving = false

    // Editable fields
    var editedTitle = ""
    var editedArtist = ""
    var editedAlbum = ""
    var editedAlbumArtist = ""
    var editedGenre = ""
    var editedYear = ""

    var hasChanges: Bool {
        guard let track = track else { return false }
        return editedTitle != (track.metadata.title ?? "")
            || editedArtist != (track.metadata.artist ?? "")
            || editedAlbum != (track.metadata.album ?? "")
            || editedAlbumArtist != (track.metadata.albumArtist ?? "")
            || editedGenre != (track.metadata.genre ?? "")
            || editedYear != (track.metadata.year.map(String.init) ?? "")
    }

    func loadTrack(_ track: TrackItem) {
        self.track = track
        editedTitle = track.metadata.title ?? ""
        editedArtist = track.metadata.artist ?? ""
        editedAlbum = track.metadata.album ?? ""
        editedAlbumArtist = track.metadata.albumArtist ?? ""
        editedGenre = track.metadata.genre ?? ""
        editedYear = track.metadata.year.map(String.init) ?? ""
        lyricsError = nil
        artworkError = nil
    }

    func fetchLyrics() async {
        guard let track = track,
              let title = track.metadata.title,
              let artist = track.metadata.artist else { return }

        isFetchingLyrics = true
        lyricsError = nil

        do {
            let result = try await LRCLIBService.fetchLyrics(
                title: title,
                artist: artist,
                album: track.metadata.album,
                duration: track.metadata.duration
            )

            if let result = result, let plain = result.plainLyrics {
                _ = try BackupService.createBackup(for: track.fileURL)
                try ID3Service.writeMetadata(to: track.fileURL, actions: [
                    .embedLyrics(plain: plain, synced: result.syncedLyrics)
                ])
                let updated = try ID3Service.readMetadata(from: track.fileURL)
                track.metadata = updated
                track.issues = MetadataCleaner.detectIssues(in: updated, fileURL: track.fileURL)
            } else {
                lyricsError = "No lyrics found for this track."
            }
        } catch {
            lyricsError = error.localizedDescription
        }

        isFetchingLyrics = false
    }

    func fetchArtwork() async {
        guard let track = track,
              let artist = track.metadata.artist,
              let album = track.metadata.album else { return }

        isFetchingArtwork = true
        artworkError = nil

        do {
            if let data = try await CoverArtService.fetchArtwork(artist: artist, album: album) {
                _ = try BackupService.createBackup(for: track.fileURL)
                try ID3Service.writeMetadata(to: track.fileURL, actions: [.embedArtwork(data)])
                let updated = try ID3Service.readMetadata(from: track.fileURL)
                track.metadata = updated
                track.issues = MetadataCleaner.detectIssues(in: updated, fileURL: track.fileURL)
            } else {
                artworkError = "No artwork found for this album."
            }
        } catch {
            artworkError = error.localizedDescription
        }

        isFetchingArtwork = false
    }

    func saveChanges() async {
        guard let track = track else { return }

        isSaving = true
        var actions: [RepairAction] = []

        if editedTitle != (track.metadata.title ?? "") {
            actions.append(.setTitle(editedTitle))
        }
        if editedArtist != (track.metadata.artist ?? "") {
            actions.append(.setArtist(editedArtist))
        }
        if editedAlbum != (track.metadata.album ?? "") {
            actions.append(.setAlbum(editedAlbum))
        }

        // Add cleaning actions for detected issues
        let cleanActions = MetadataCleaner.suggestRepairs(for: track.issues, metadata: track.metadata, fileURL: track.fileURL)
        actions.append(contentsOf: cleanActions)

        do {
            if !actions.isEmpty {
                _ = try BackupService.createBackup(for: track.fileURL)
                try ID3Service.writeMetadata(to: track.fileURL, actions: actions)
                let updated = try ID3Service.readMetadata(from: track.fileURL)
                track.metadata = updated
                track.issues = MetadataCleaner.detectIssues(in: updated, fileURL: track.fileURL)
                track.status = .fixed
                loadTrack(track)
            }
        } catch {
            track.status = .error
            track.errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
