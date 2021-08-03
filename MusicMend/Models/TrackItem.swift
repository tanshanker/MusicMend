import Foundation

enum TrackStatus: String {
    case scanned
    case processing
    case fixed
    case error
}

@Observable
class TrackItem: Identifiable {
    let id: UUID
    let fileURL: URL
    var metadata: TrackMetadata
    var issues: [MetadataIssue]
    var pendingActions: [RepairAction]
    var status: TrackStatus
    var errorMessage: String?

    init(fileURL: URL, metadata: TrackMetadata = .empty()) {
        self.id = UUID()
        self.fileURL = fileURL
        self.metadata = metadata
        self.issues = []
        self.pendingActions = []
        self.status = .scanned
    }

    var fileName: String {
        fileURL.lastPathComponent
    }

    var hasIssues: Bool {
        !issues.isEmpty
    }

    var issueCount: Int {
        issues.count
    }

    var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }
}

extension TrackItem: Hashable {
    static func == (lhs: TrackItem, rhs: TrackItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
