import Foundation

actor ExchangeRateService {
    private var cachedRates: [String: Double]?
    private var cachedTimestamp: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    func fetchRates(base: String = "USD") async throws -> (rates: [String: Double], timestamp: Date) {
        if let cached = cachedRates, let ts = cachedTimestamp,
           Date().timeIntervalSince(ts) < cacheDuration {
            return (cached, ts)
        }

        let url = URL(string: "https://open.er-api.com/v6/latest/\(base)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)

        guard response.result == "success" else {
            throw ExchangeRateError.apiFailed
        }

        let timestamp = Date(timeIntervalSince1970: TimeInterval(response.timeLastUpdateUnix))
        cachedRates = response.rates
        cachedTimestamp = Date()

        return (response.rates, timestamp)
    }

    func invalidateCache() {
        cachedRates = nil
        cachedTimestamp = nil
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
