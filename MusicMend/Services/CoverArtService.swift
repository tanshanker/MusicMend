import Foundation

struct CoverArtService {
    private static let baseURL = "https://coverartarchive.org"
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "MusicMend/1.0"]
        return URLSession(configuration: config)
    }()

    static func fetchFrontCover(mbid: String) async throws -> Data? {
        // Try 500px version first for good quality without being too large
        if let data = try await fetchImage(mbid: mbid, suffix: "front-500") {
            return data
        }
        // Fall back to default front cover
        return try await fetchImage(mbid: mbid, suffix: "front")
    }

    private static func fetchImage(mbid: String, suffix: String) async throws -> Data? {
        guard let url = URL(string: "\(baseURL)/release/\(mbid)/\(suffix)") else {
            return nil
        }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { return nil }

        if httpResponse.statusCode == 404 { return nil }
        guard httpResponse.statusCode == 200 else { return nil }

        // Verify it's actually image data
        guard data.count > 100 else { return nil }

        return data
    }

    static func fetchArtwork(artist: String, album: String) async throws -> Data? {
        guard let release = try await MusicBrainzService.searchRelease(artist: artist, album: album) else {
            return nil
        }
        return try await fetchFrontCover(mbid: release.mbid)
    }
}
