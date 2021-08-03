import Foundation

struct TrackMetadata: Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var trackNumber: Int?
    var discNumber: Int?
    var year: Int?
    var genre: String?
    var hasArtwork: Bool = false
    var artworkData: Data?
    var hasLyrics: Bool = false
    var lyricsText: String?
    var syncedLyrics: String?
    var duration: TimeInterval?

    static func empty() -> TrackMetadata {
        TrackMetadata()
    }

    var displayTitle: String {
        title ?? "Unknown Title"
    }

    var displayArtist: String {
        artist ?? "Unknown Artist"
    }

    var displayAlbum: String {
        album ?? "Unknown Album"
    }
}
