import SwiftUI

struct BatchSummaryView: View {
    let processor: BatchProcessor
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: processor.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(processor.errors.isEmpty ? .green : .orange)

            Text("Processing Complete")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                HStack {
                    Text("Processed:")
                    Spacer()
                    Text("\(processor.completedCount) tracks")
                }
                HStack {
                    Text("Succeeded:")
                    Spacer()
                    Text("\(processor.completedCount - processor.errors.count)")
                        .foregroundStyle(.green)
                }
                if !processor.errors.isEmpty {
                    HStack {
                        Text("Errors:")
                        Spacer()
                        Text("\(processor.errors.count)")
                            .foregroundStyle(.red)
                    }
                }
            }
            .font(.body)
            .frame(width: 250)

            if !processor.errors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(processor.errors, id: \.0) { fileName, error in
                            HStack(alignment: .top) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                VStack(alignment: .leading) {
                                    Text(fileName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }

            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(width: 400)
    }
}
