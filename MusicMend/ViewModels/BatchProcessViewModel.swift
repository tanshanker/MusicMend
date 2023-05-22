import Foundation

@MainActor
@Observable
class BatchProcessViewModel {
    let processor = BatchProcessor()
    var showingProgress = false
    var showingSummary = false

    var fetchLyrics = true
    var fetchArtwork = true
    var cleanMetadata = true

    func processAll(tracks: [TrackItem]) async {
        showingProgress = true
        showingSummary = false

        await processor.processAll(
            tracks: tracks,
            fetchLyrics: fetchLyrics,
            fetchArtwork: fetchArtwork,
            cleanMetadata: cleanMetadata
        )

        showingProgress = false
        showingSummary = true
    }

    func cancel() {
        processor.cancel()
    }

    func dismissSummary() {
        showingSummary = false
    }
}
