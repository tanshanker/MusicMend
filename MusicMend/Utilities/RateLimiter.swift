import Foundation

actor RateLimiter {
    private let interval: TimeInterval
    private var lastRequestTime: Date = .distantPast

    init(requestsPerSecond: Double = 1.0) {
        self.interval = 1.0 / requestsPerSecond
    }

    func throttle() async {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)
        if elapsed < interval {
            let delay = interval - elapsed
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}
