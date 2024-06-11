import SwiftUI

struct ContentView: View {
    @State private var libraryVM = LibraryViewModel()
    @State private var detailVM = TrackDetailViewModel()
    @State private var batchVM = BatchProcessViewModel()
    @State private var selectedTrackID: UUID?
    @State private var showingBatchOptions = false
    @State private var showingError = false

    var selectedTrack: TrackItem? {
        guard let id = selectedTrackID else { return nil }
        return libraryVM.tracks.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: libraryVM)
                .frame(minWidth: 200)
        } content: {
            TrackListView(
                viewModel: libraryVM,
                selectedTrackID: $selectedTrackID,
                onFixAll: { showingBatchOptions = true },
                onFixSelected: {}
            )
            .frame(minWidth: 400)
        } detail: {
            if let track = selectedTrack {
                TrackDetailView(viewModel: detailVM, track: track)
                    .frame(minWidth: 300)
            } else {
                Text("Select a track to view details")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingBatchOptions) {
            batchOptionsSheet
        }
        .sheet(isPresented: $batchVM.showingProgress) {
            BatchProgressView(
                processor: batchVM.processor,
                onCancel: { batchVM.cancel() }
            )
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $batchVM.showingSummary) {
            BatchSummaryView(
                processor: batchVM.processor,
                onDismiss: { batchVM.dismissSummary() }
            )
        }
        .onChange(of: libraryVM.errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { libraryVM.errorMessage = nil }
        } message: {
            Text(libraryVM.errorMessage ?? "")
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private var batchOptionsSheet: some View {
        VStack(spacing: 24) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 36))
                .foregroundStyle(.tint)

            Text("Fix All Tracks")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Fetch missing lyrics", isOn: $batchVM.fetchLyrics)
                Toggle("Fetch missing artwork", isOn: $batchVM.fetchArtwork)
                Toggle("Clean bad metadata (URLs, spam, encoding)", isOn: $batchVM.cleanMetadata)
            }
            .frame(width: 300)

            VStack(spacing: 4) {
                Text("\(libraryVM.filteredTracks.count) tracks will be processed")
                    .font(.callout)
                if libraryVM.missingLyricsCount > 0 || libraryVM.missingArtworkCount > 0 {
                    Text("\(libraryVM.missingLyricsCount) missing lyrics, \(libraryVM.missingArtworkCount) missing artwork")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    showingBatchOptions = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Fix Everything") {
                    showingBatchOptions = false
                    Task {
                        await batchVM.processAll(tracks: libraryVM.filteredTracks)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 400)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data = data as? Data,
                      let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let url = URL(string: path) else { return }

                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    Task { @MainActor in
                        await libraryVM.scanCustomFolder(url)
                    }
                }
            }
        }
        return true
    }
}
