import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: LibraryViewModel

    var body: some View {
        List {
            Section("Source") {
                Button {
                    Task { await viewModel.scanMusicLibrary() }
                } label: {
                    Label("Music Library", systemImage: "music.note.house")
                }
                .buttonStyle(.plain)

                Button {
                    chooseFolder()
                } label: {
                    Label("Choose Folder...", systemImage: "folder")
                }
                .buttonStyle(.plain)
            }

            if !viewModel.tracks.isEmpty {
                Section("Filters") {
                    ForEach(LibraryFilter.allCases, id: \.self) { filter in
                        let isActive = viewModel.filter == filter
                        Button {
                            viewModel.filter = filter
                        } label: {
                            HStack {
                                Image(systemName: iconForFilter(filter))
                                    .frame(width: 18)
                                    .foregroundStyle(isActive ? .white : .secondary)
                                Text(filter.rawValue)
                                    .foregroundStyle(isActive ? .white : .primary)
                                Spacer()
                                Text("\(countForFilter(filter))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isActive ? Color.accentColor : Color.clear)
                        )
                    }
                }

                Section("Stats") {
                    StatRow(label: "Total Tracks", value: "\(viewModel.tracks.count)")
                    StatRow(label: "Issues Found", value: "\(viewModel.totalIssueCount)")
                    StatRow(label: "Missing Lyrics", value: "\(viewModel.missingLyricsCount)")
                    StatRow(label: "Missing Artwork", value: "\(viewModel.missingArtworkCount)")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MusicMend")
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing MP3 files"

        if panel.runModal() == .OK, let url = panel.url {
            Task { await viewModel.scanCustomFolder(url) }
        }
    }

    private func iconForFilter(_ filter: LibraryFilter) -> String {
        switch filter {
        case .all: return "music.note.list"
        case .missingLyrics: return "text.quote"
        case .missingArtwork: return "photo"
        case .badMetadata: return "exclamationmark.triangle"
        case .hasIssues: return "magnifyingglass"
        }
    }

    private func countForFilter(_ filter: LibraryFilter) -> Int {
        switch filter {
        case .all: return viewModel.tracks.count
        case .missingLyrics: return viewModel.missingLyricsCount
        case .missingArtwork: return viewModel.missingArtworkCount
        case .badMetadata:
            return viewModel.tracks.filter { track in
                track.issues.contains(where: {
                    if case .suspiciousURL = $0 { return true }
                    if case .spamText = $0 { return true }
                    if case .encodingArtifacts = $0 { return true }
                    return false
                })
            }.count
        case .hasIssues: return viewModel.tracksWithIssues
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}
