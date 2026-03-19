import Foundation

struct ExchangeRateResponse: Codable, Sendable {
    let result: String
    let baseCode: String
    let timeLastUpdateUnix: Int
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case rates
    }
}
