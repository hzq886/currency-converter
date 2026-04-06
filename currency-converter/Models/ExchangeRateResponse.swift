import Foundation

struct ExchangeRateResponse: Codable, Sendable {
    let base: String
    let timestamp: String
    let rates: [String: Double]
}
