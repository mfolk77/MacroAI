import Foundation
import Combine

final class AppUpdateManager: ObservableObject {
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String?
    @Published var appStoreURL: URL?

    private var isChecking: Bool = false
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = AppUpdateManager.makeSession()) {
        self.session = session
    }

    func checkForUpdate() {
        guard !isChecking else { return }
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        isChecking = true

        let countryCode = Locale.current.regionCode ?? "US"
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId),
            URLQueryItem(name: "country", value: countryCode)
        ]

        guard let url = components?.url else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 3)
        request.httpMethod = "GET"

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.isChecking = false }

            if let error = error {
                #if DEBUG
                print("[AppUpdateManager] Lookup failed: \(error)")
                #endif
                return
            }
            guard let data = data else { return }
            do {
                let result = try self.decoder.decode(LookupResponse.self, from: data)
                guard let app = result.results.first else { return }

                let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
                if Self.isVersion(app.version, greaterThan: currentVersion) {
                    DispatchQueue.main.async {
                        self.latestVersion = app.version
                        self.appStoreURL = URL(string: app.trackViewUrl)
                        self.updateAvailable = true
                    }
                }
            } catch {
                #if DEBUG
                print("[AppUpdateManager] Decode failed: \(error)")
                #endif
            }
        }.resume()
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 3
        config.timeoutIntervalForResource = 3
        return URLSession(configuration: config)
    }

    private static func isVersion(_ lhs: String, greaterThan rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(lhsParts.count, rhsParts.count)
        for i in 0..<maxCount {
            let l = i < lhsParts.count ? lhsParts[i] : 0
            let r = i < rhsParts.count ? rhsParts[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}

private struct LookupResponse: Decodable {
    let resultCount: Int
    let results: [AppInfo]
}

private struct AppInfo: Decodable {
    let version: String
    let trackViewUrl: String
}


