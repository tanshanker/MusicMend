import SwiftUI

struct BatchProgressView: View {
    let processor: BatchProcessor
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Processing Tracks")
                .font(.title2)
                .fontWeight(.semibold)

            ProgressView(value: processor.progress) {
                Text("\(processor.completedCount) of \(processor.totalCount)")
                    .font(.caption)
            }
            .progressViewStyle(.linear)
            .frame(width: 300)

            if !processor.currentTrackName.isEmpty {
                Text(processor.currentTrackName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text("\(Int(processor.progress * 100))%")
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()

            Button("Cancel") {
                onCancel()
            }
            .controlSize(.large)
        }
        .padding(40)
        .frame(width: 400)
    }
}
