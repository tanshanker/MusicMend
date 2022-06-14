import Foundation

struct LyricsResult {
    let plainLyrics: String?
    let syncedLyrics: String?
    let isInstrumental: Bool
}

struct LRCLIBService {
    private static let baseURL = "https://lrclib.net/api"
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "MusicMend/1.0"]
        return URLSession(configuration: config)
    }()

    static func fetchLyrics(
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval? = nil
    ) async throws -> LyricsResult? {
        // Try exact match first
        if let result = try await fetchExact(title: title, artist: artist, album: album, duration: duration) {
            return result
        }
        // Fall back to search
        return try await searchLyrics(title: title, artist: artist)
    }

    private static func fetchExact(
        title: String,
        artist: String,
        album: String?,
        duration: TimeInterval?
    ) async throws -> LyricsResult? {
        guard var components = URLComponents(string: "\(baseURL)/get") else { return nil }
        var queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        if let album = album {
            queryItems.append(URLQueryItem(name: "album_name", value: album))
        }
        if let duration = duration {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components.queryItems = queryItems

        guard let url = components.url else { return nil }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { return nil }
        if httpResponse.statusCode == 404 { return nil }
        guard httpResponse.statusCode == 200 else { return nil }

        return try parseLyricsResponse(data)
    }

    private static func searchLyrics(title: String, artist: String) async throws -> LyricsResult? {
        guard var components = URLComponents(string: "\(baseURL)/search") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]

        guard let url = components.url else { return nil }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        guard let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = results.first else { return nil }

        let plain = first["plainLyrics"] as? String
        let synced = first["syncedLyrics"] as? String
        let instrumental = first["instrumental"] as? Bool ?? false

        if instrumental { return LyricsResult(plainLyrics: nil, syncedLyrics: nil, isInstrumental: true) }
        if plain == nil && synced == nil { return nil }

        return LyricsResult(plainLyrics: plain, syncedLyrics: synced, isInstrumental: false)
    }

    private static func parseLyricsResponse(_ data: Data) throws -> LyricsResult? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let instrumental = json["instrumental"] as? Bool ?? false
        if instrumental {
            return LyricsResult(plainLyrics: nil, syncedLyrics: nil, isInstrumental: true)
        }

        let plain = json["plainLyrics"] as? String
        let synced = json["syncedLyrics"] as? String

        if plain == nil && synced == nil { return nil }

        return LyricsResult(plainLyrics: plain, syncedLyrics: synced, isInstrumental: false)
    }
}
