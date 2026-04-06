import Foundation

actor ExchangeRateService {
    private var cachedRates: [String: Double]?
    private var cachedFetchedAt: Date?
    private var cachedAPITimestamp: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    func fetchRates(base: String = "USD") async throws -> (rates: [String: Double], timestamp: Date) {
        if let cached = cachedRates, let fetchedAt = cachedFetchedAt, let apiTimestamp = cachedAPITimestamp,
           Date().timeIntervalSince(fetchedAt) < cacheDuration {
            return (cached, apiTimestamp)
        }

        let url = URL(string: "https://fxapi.app/api/\(base.lowercased()).json")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ExchangeRateError.apiFailed
        }

        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.date(from: decoded.timestamp) ?? Date()
        var rates = decoded.rates.compactMapValues { $0 }
        rates[base.uppercased()] = 1.0
        cachedRates = rates
        cachedFetchedAt = Date()
        cachedAPITimestamp = timestamp

        return (cachedRates!, timestamp)
    }

    func invalidateCache() {
        cachedRates = nil
        cachedFetchedAt = nil
        cachedAPITimestamp = nil
    }
}

enum ExchangeRateError: LocalizedError {
    case apiFailed

    var errorDescription: String? {
        switch self {
        case .apiFailed: return "Failed to fetch exchange rates"
        }
    }
}
