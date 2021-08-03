import Foundation

enum RepairAction: Identifiable {
    case setTitle(String)
    case setArtist(String)
    case setAlbum(String)
    case embedArtwork(Data)
    case embedLyrics(plain: String, synced: String?)
    case cleanField(field: String, original: String, cleaned: String)
    case removeField(field: String)
    case renameFile(from: String, to: String)

    var id: String {
        switch self {
        case .setTitle: return "set_title"
        case .setArtist: return "set_artist"
        case .setAlbum: return "set_album"
        case .embedArtwork: return "embed_artwork"
        case .embedLyrics: return "embed_lyrics"
        case .cleanField(let field, _, _): return "clean_\(field)"
        case .removeField(let field): return "remove_\(field)"
        case .renameFile: return "rename_file"
        }
    }

    var description: String {
        switch self {
        case .setTitle(let value): return "Set title to \"\(value)\""
        case .setArtist(let value): return "Set artist to \"\(value)\""
        case .setAlbum(let value): return "Set album to \"\(value)\""
        case .embedArtwork: return "Embed album artwork"
        case .embedLyrics: return "Embed lyrics"
        case .cleanField(let field, _, let cleaned):
            return "Clean \(field) to \"\(cleaned)\""
        case .removeField(let field): return "Remove \(field)"
        case .renameFile(_, let to): return "Rename file to \"\(to)\""
        }
    }
}
