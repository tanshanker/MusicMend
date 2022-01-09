import Foundation
import ID3TagEditor

struct ID3Service {
    private static let editor = ID3TagEditor()

    static func readMetadata(from url: URL) throws -> TrackMetadata {
        guard let tag = try editor.read(from: url.path) else {
            return .empty()
        }

        let reader = ID3TagContentReader(id3Tag: tag)
        var metadata = TrackMetadata()

        metadata.title = reader.title()
        metadata.artist = reader.artist()
        metadata.album = reader.album()
        metadata.albumArtist = reader.albumArtist()
        metadata.genre = reader.genre()?.description

        if let trackPosition = reader.trackPosition() {
            metadata.trackNumber = trackPosition.position
        }

        if let discPosition = reader.discPosition() {
            metadata.discNumber = discPosition.position
        }

        if let recordingYear = reader.recordingYear() {
            metadata.year = recordingYear
        }

        let pictures = reader.attachedPictures()
        if let frontCover = pictures.first(where: { $0.type == .frontCover }) {
            metadata.hasArtwork = true
            metadata.artworkData = frontCover.picture
        } else if let anyPicture = pictures.first {
            metadata.hasArtwork = true
            metadata.artworkData = anyPicture.picture
        }

        if let lyrics = reader.unsynchronizedLyrics().first {
            let text = lyrics.content
            if !text.isEmpty {
                metadata.hasLyrics = true
                metadata.lyricsText = text
            }
        }

        return metadata
    }

    static func writeMetadata(to url: URL, actions: [RepairAction]) throws {
        let existingTag = try editor.read(from: url.path)

        var builder = ID32v3TagBuilder()

        // Preserve existing fields first
        if let tag = existingTag {
            let reader = ID3TagContentReader(id3Tag: tag)
            if let title = reader.title() {
                builder = builder.title(frame: ID3FrameWithStringContent(content: title))
            }
            if let artist = reader.artist() {
                builder = builder.artist(frame: ID3FrameWithStringContent(content: artist))
            }
            if let album = reader.album() {
                builder = builder.album(frame: ID3FrameWithStringContent(content: album))
            }
            if let albumArtist = reader.albumArtist() {
                builder = builder.albumArtist(frame: ID3FrameWithStringContent(content: albumArtist))
            }
            if let genre = reader.genre() {
                builder = builder.genre(frame: ID3FrameGenre(genre: genre.identifier, description: genre.description))
            }
            if let trackPosition = reader.trackPosition() {
                builder = builder.trackPosition(frame: ID3FramePartOfTotal(part: trackPosition.position, total: trackPosition.total))
            }
            if let discPosition = reader.discPosition() {
                builder = builder.discPosition(frame: ID3FramePartOfTotal(part: discPosition.position, total: discPosition.total))
            }
            if let year = reader.recordingYear() {
                builder = builder.recordingYear(frame: ID3FrameWithIntegerContent(value: year))
            }

            let pictures = reader.attachedPictures()
            for picture in pictures {
                builder = builder.attachedPicture(pictureType: picture.type, frame: ID3FrameAttachedPicture(picture: picture.picture, type: picture.type, format: picture.format))
            }

            let lyrics = reader.unsynchronizedLyrics()
            for lyric in lyrics {
                builder = builder.unsynchronisedLyrics(language: lyric.language, frame: ID3FrameWithLocalizedContent(language: lyric.language, contentDescription: lyric.contentDescription, content: lyric.content))
            }
        }

        // Apply repair actions (overwriting relevant fields)
        for action in actions {
            switch action {
            case .setTitle(let value):
                builder = builder.title(frame: ID3FrameWithStringContent(content: value))
            case .setArtist(let value):
                builder = builder.artist(frame: ID3FrameWithStringContent(content: value))
            case .setAlbum(let value):
                builder = builder.album(frame: ID3FrameWithStringContent(content: value))
            case .embedArtwork(let data):
                builder = builder.attachedPicture(
                    pictureType: .frontCover,
                    frame: ID3FrameAttachedPicture(
                        picture: data,
                        type: .frontCover,
                        format: .jpeg
                    )
                )
            case .embedLyrics(let plain, _):
                builder = builder.unsynchronisedLyrics(
                    language: .eng,
                    frame: ID3FrameWithLocalizedContent(
                        language: .eng,
                        contentDescription: "Lyrics",
                        content: plain
                    )
                )
            case .cleanField(let field, _, let cleaned):
                switch field {
                case "title":
                    builder = builder.title(frame: ID3FrameWithStringContent(content: cleaned))
                case "artist":
                    builder = builder.artist(frame: ID3FrameWithStringContent(content: cleaned))
                case "album":
                    builder = builder.album(frame: ID3FrameWithStringContent(content: cleaned))
                default:
                    break
                }
            case .removeField:
                break
            case .renameFile:
                break // handled outside ID3Service
            }
        }

        let newTag = builder.build()
        try editor.write(tag: newTag, to: url.path)
    }
}
