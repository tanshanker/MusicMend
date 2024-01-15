import SwiftUI

struct LyricsView: View {
    let lyrics: String?
    let isFetching: Bool
    let error: String?
    let onFetch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Lyrics", systemImage: "text.quote")
                    .font(.headline)
                Spacer()
                if isFetching {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button("Fetch Lyrics") {
                        onFetch()
                    }
                    .controlSize(.small)
                }
            }

            if let lyrics = lyrics, !lyrics.isEmpty {
                ScrollView {
                    Text(lyrics)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
            } else {
                Text("No lyrics embedded")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(8)
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
