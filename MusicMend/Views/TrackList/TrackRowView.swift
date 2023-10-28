import SwiftUI

struct TrackRowView: View {
    let track: TrackItem
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            StatusIndicator(status: track.status, issueCount: track.issueCount)

            // Artwork thumbnail
            if let artworkData = track.metadata.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
            }

            // Track info — title + artist
            VStack(alignment: .leading, spacing: 2) {
                Text(track.metadata.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                Text(track.metadata.displayArtist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 160, alignment: .leading)

            Spacer(minLength: 8)

            // Album
            Text(track.metadata.displayAlbum)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            Spacer(minLength: 8)

            // Status pills
            HStack(spacing: 6) {
                // Lyrics
                statusPill(
                    icon: "text.quote",
                    label: "Lyrics",
                    isPresent: track.metadata.hasLyrics
                )

                // Artwork
                statusPill(
                    icon: "photo",
                    label: "Art",
                    isPresent: track.metadata.hasArtwork
                )
            }

            // Issues badge
            if track.issueCount > 0 {
                Text("\(track.issueCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(track.warningCount > 0 ? Color.orange : Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private func statusPill(icon: String, label: String, isPresent: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: isPresent ? "\(icon).fill" : icon)
                .font(.system(size: 9))
            Text(label)
                .font(.system(size: 9))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isPresent ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
        .foregroundStyle(isPresent ? .green : .secondary)
        .cornerRadius(4)
    }
}
