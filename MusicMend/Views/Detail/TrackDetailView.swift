import SwiftUI

struct TrackDetailView: View {
    @Bindable var viewModel: TrackDetailViewModel
    let track: TrackItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artwork
                HStack {
                    Spacer()
                    ArtworkView(
                        artworkData: track.metadata.artworkData,
                        isFetching: viewModel.isFetchingArtwork,
                        error: viewModel.artworkError,
                        onFetch: { Task { await viewModel.fetchArtwork() } }
                    )
                    Spacer()
                }

                Divider()

                // Metadata fields
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metadata")
                        .font(.headline)

                    MetadataFieldRow(label: "Title", value: $viewModel.editedTitle)
                    MetadataFieldRow(label: "Artist", value: $viewModel.editedArtist)
                    MetadataFieldRow(label: "Album", value: $viewModel.editedAlbum)
                    MetadataFieldRow(label: "Album Artist", value: $viewModel.editedAlbumArtist)
                    MetadataFieldRow(label: "Genre", value: $viewModel.editedGenre)
                    MetadataFieldRow(label: "Year", value: $viewModel.editedYear)

                    if let trackNum = track.metadata.trackNumber {
                        HStack {
                            Text("Track")
                                .frame(width: 100, alignment: .trailing)
                                .foregroundStyle(.secondary)
                            Text("\(trackNum)")
                        }
                    }
                }

                // Issues
                if !track.issues.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issues (\(track.issues.count))")
                            .font(.headline)
                        ForEach(track.issues) { issue in
                            HStack(spacing: 6) {
                                Image(systemName: issue.severity == .warning
                                      ? "exclamationmark.triangle.fill"
                                      : "info.circle.fill")
                                    .foregroundStyle(issue.severity == .warning ? .orange : .blue)
                                    .font(.caption)
                                Text(issue.description)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Divider()

                // Lyrics
                LyricsView(
                    lyrics: track.metadata.lyricsText,
                    isFetching: viewModel.isFetchingLyrics,
                    error: viewModel.lyricsError,
                    onFetch: { Task { await viewModel.fetchLyrics() } }
                )

                Divider()

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Info")
                        .font(.headline)
                    Text(track.fileURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                // Save button
                if viewModel.hasChanges {
                    HStack {
                        Spacer()
                        Button("Revert") {
                            viewModel.loadTrack(track)
                        }
                        Button("Save Changes") {
                            Task { await viewModel.saveChanges() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSaving)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadTrack(track)
        }
        .onChange(of: track.id) { _, _ in
            viewModel.loadTrack(track)
        }
    }
}

struct MetadataFieldRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .trailing)
                .foregroundStyle(.secondary)
            TextField(label, text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}
