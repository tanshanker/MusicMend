import Foundation

struct MusicBrainzRelease {
    let mbid: String
    let title: String
    let score: Int
}

struct MusicBrainzService {
    private static let baseURL = "https://musicbrainz.org/ws/2"
    private static let rateLimiter = RateLimiter(requestsPerSecond: 1.0)
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "MusicMend/1.0 (musicmend@example.com)",
            "Accept": "application/json",
        ]
        return URLSession(configuration: config)
    }()

    static func searchRelease(artist: String, album: String) async throws -> MusicBrainzRelease? {
        await rateLimiter.throttle()

        let query = "artist:\"\(artist)\" AND release:\"\(album)\""
        guard var components = URLComponents(string: "\(baseURL)/release") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "5"),
        ]

        guard let url = components.url else { return nil }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let releases = json["releases"] as? [[String: Any]] else { return nil }

        // Find best match
        var bestRelease: MusicBrainzRelease?
        var bestScore = 0

        for release in releases {
            guard let id = release["id"] as? String,
                  let title = release["title"] as? String,
                  let score = release["score"] as? Int else { continue }

            if score > bestScore {
                bestScore = score
                bestRelease = MusicBrainzRelease(mbid: id, title: title, score: score)
            }
        }

        return bestRelease
    }
}
