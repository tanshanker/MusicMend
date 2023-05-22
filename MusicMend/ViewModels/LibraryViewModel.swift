import Foundation
import SwiftUI

enum LibraryFilter: String, CaseIterable {
    case all = "All"
    case missingLyrics = "Missing Lyrics"
    case missingArtwork = "Missing Artwork"
    case badMetadata = "Bad Metadata"
    case hasIssues = "Has Issues"
}

enum ScanSource {
    case musicLibrary
    case customFolder(URL)
}

@MainActor
@Observable
class LibraryViewModel {
    var tracks: [TrackItem] = []
    var searchText = ""
    var filter: LibraryFilter = .all
    var isScanning = false
    var scanProgress = ""
    var currentSource: ScanSource?
    var errorMessage: String?

    var filteredTracks: [TrackItem] {
        var result = tracks

        // Apply filter
        switch filter {
        case .all:
            break
        case .missingLyrics:
            result = result.filter { !$0.metadata.hasLyrics }
        case .missingArtwork:
            result = result.filter { !$0.metadata.hasArtwork }
        case .badMetadata:
            result = result.filter { track in
                track.issues.contains(where: {
                    if case .suspiciousURL = $0 { return true }
                    if case .spamText = $0 { return true }
                    if case .encodingArtifacts = $0 { return true }
                    return false
                })
            }
        case .hasIssues:
            result = result.filter { $0.hasIssues }
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.metadata.displayTitle.lowercased().contains(query)
                || $0.metadata.displayArtist.lowercased().contains(query)
                || $0.metadata.displayAlbum.lowercased().contains(query)
            }
        }

        return result
    }

    var totalIssueCount: Int {
        tracks.reduce(0) { $0 + $1.issueCount }
    }

    var tracksWithIssues: Int {
        tracks.filter { $0.hasIssues }.count
    }

    var missingLyricsCount: Int {
        tracks.filter { !$0.metadata.hasLyrics }.count
    }

    var missingArtworkCount: Int {
        tracks.filter { !$0.metadata.hasArtwork }.count
    }

    func scanMusicLibrary() async {
        await scan(url: FileScanner.defaultMusicPath)
        currentSource = .musicLibrary
    }

    func scanCustomFolder(_ url: URL) async {
        await scan(url: url)
        currentSource = .customFolder(url)
    }

    private func scan(url: URL) async {
        isScanning = true
        tracks = []
        errorMessage = nil
        scanProgress = "Discovering MP3 files..."

        do {
            let mp3URLs = try await Task.detached {
                try FileScanner.scanDirectory(url)
            }.value
            scanProgress = "Reading metadata for \(mp3URLs.count) files..."

            for (index, fileURL) in mp3URLs.enumerated() {
                let track: TrackItem = await Task.detached {
                    do {
                        let metadata = try ID3Service.readMetadata(from: fileURL)
                        let t = TrackItem(fileURL: fileURL, metadata: metadata)
                        t.issues = MetadataCleaner.detectIssues(in: metadata, fileURL: fileURL)
                        return t
                    } catch {
                        let t = TrackItem(fileURL: fileURL)
                        t.status = .error
                        t.errorMessage = error.localizedDescription
                        return t
                    }
                }.value
                tracks.append(track)

                if index % 10 == 0 {
                    scanProgress = "Reading metadata... \(index + 1)/\(mp3URLs.count)"
                }
            }

            scanProgress = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isScanning = false
    }

    func refreshTrack(_ track: TrackItem) {
        do {
            let metadata = try ID3Service.readMetadata(from: track.fileURL)
            track.metadata = metadata
            track.issues = MetadataCleaner.detectIssues(in: metadata, fileURL: track.fileURL)
            track.status = .scanned
            track.errorMessage = nil
        } catch {
            track.status = .error
            track.errorMessage = error.localizedDescription
        }
    }
}
