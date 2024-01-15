import SwiftUI

struct ArtworkView: View {
    let artworkData: Data?
    let isFetching: Bool
    let error: String?
    let onFetch: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let data = artworkData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("No Artwork")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }

            if isFetching {
                ProgressView("Fetching artwork...")
                    .font(.caption)
            } else {
                Button("Fetch Artwork") {
                    onFetch()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
