import SwiftUI

struct TrackListView: View {
    @Bindable var viewModel: LibraryViewModel
    @Binding var selectedTrackID: UUID?
    let onFixAll: () -> Void
    let onFixSelected: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(viewModel.scanProgress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tracks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Fix All Issues bar
                    if viewModel.tracksWithIssues > 0 {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("\(viewModel.tracksWithIssues) tracks with issues")
                                .font(.callout)
                            Spacer()
                            Button {
                                onFixAll()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                    Text("Fix All Issues")
                                }
                                .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.regular)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.08))
                    }

                    // Column header
                    HStack(spacing: 10) {
                        Text("")
                            .frame(width: 20) // status icon
                        Text("")
                            .frame(width: 36) // artwork
                        Text("Title / Artist")
                            .frame(minWidth: 160, alignment: .leading)
                        Spacer(minLength: 8)
                        Text("Album")
                            .frame(width: 120, alignment: .leading)
                        Spacer(minLength: 8)
                        Text("Status")
                            .frame(width: 110, alignment: .leading)
                        Text("")
                            .frame(width: 30) // badge
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .separatorColor).opacity(0.2))

                    trackList
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tracks...")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No tracks loaded")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Select your Music Library or choose a folder from the sidebar to get started.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trackList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredTracks) { track in
                    TrackRowView(track: track, isSelected: selectedTrackID == track.id)
                        .onTapGesture {
                            selectedTrackID = track.id
                        }
                        .contextMenu {
                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([track.fileURL])
                            }
                            Divider()
                            Button("Refresh Metadata") {
                                viewModel.refreshTrack(track)
                            }
                        }
                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
