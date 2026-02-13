//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Service for fetching App Store version information.
public final class AppStoreVersionService {
    /// Initializes a new instance of the service.
    public init() {}

    /// Fetches the latest App Store version for the given App Store identifier.
    ///
    /// - Parameter appStoreId: The App Store identifier to look up.
    /// - Returns: The App Store version string if available.
    public func fetchAppStoreVersion(appStoreId: String) async -> String? {
        guard let url = lookupURL(appStoreId: appStoreId) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
            return response.results.first?.version
        } catch {
            return nil
        }
    }

    /// Builds the App Store lookup URL for the App Store identifier.
    ///
    /// - Parameter appStoreId: The App Store identifier to look up.
    /// - Returns: A URL for the App Store lookup endpoint.
    private func lookupURL(appStoreId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        components.queryItems = [URLQueryItem(name: "id", value: appStoreId)]
        return components.url
    }
}

/// Response model for App Store lookup.
private struct AppStoreLookupResponse: Decodable {
    /// Results returned by the lookup.
    let results: [AppStoreLookupResult]
}

/// Result entry from the App Store lookup response.
private struct AppStoreLookupResult: Decodable {
    /// The App Store version string.
    let version: String?
}
