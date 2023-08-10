import SwiftUI

struct StatusIndicator: View {
    let status: TrackStatus
    let issueCount: Int

    var body: some View {
        ZStack {
            switch status {
            case .scanned:
                if issueCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            case .processing:
                ProgressView()
                    .scaleEffect(0.6)
            case .fixed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 20, height: 20)
    }
}

struct IssuesBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(count > 2 ? Color.red : Color.orange)
                .clipShape(Capsule())
        }
    }
}
