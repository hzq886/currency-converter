import Foundation

enum CurrencyRegion: String, CaseIterable, Codable, Sendable {
    case asia = "アジア"
    case westernEurope = "西ヨーロッパ"
    case northAmerica = "北米"
    case oceania = "オセアニア"
    case other = "その他"
}

struct CurrencyInfo: Identifiable, Hashable, Codable, Sendable {
    var id: String { code }
    let code: String
    let name: String
    let localizedName: String
    let flagCode: String
    let region: CurrencyRegion

    var flagURL: URL? {
        URL(string: "https://flagcdn.com/w160/\(flagCode).png")
    }
}

extension CurrencyInfo {
    static let allCurrencies: [CurrencyInfo] = [
        // Asia
        CurrencyInfo(code: "JPY", name: "Japanese Yen", localizedName: "日本円", flagCode: "jp", region: .asia),
        CurrencyInfo(code: "CNY", name: "Chinese Yuan", localizedName: "中国人民元", flagCode: "cn", region: .asia),
        CurrencyInfo(code: "KRW", name: "South Korean Won", localizedName: "韓国ウォン", flagCode: "kr", region: .asia),
        CurrencyInfo(code: "TWD", name: "New Taiwan Dollar", localizedName: "新台湾ドル", flagCode: "tw", region: .asia),
        CurrencyInfo(code: "HKD", name: "Hong Kong Dollar", localizedName: "香港ドル", flagCode: "hk", region: .asia),
        CurrencyInfo(code: "SGD", name: "Singapore Dollar", localizedName: "シンガポールドル", flagCode: "sg", region: .asia),
        CurrencyInfo(code: "THB", name: "Thai Baht", localizedName: "タイバーツ", flagCode: "th", region: .asia),
        CurrencyInfo(code: "VND", name: "Vietnamese Dong", localizedName: "ベトナムドン", flagCode: "vn", region: .asia),
        CurrencyInfo(code: "PHP", name: "Philippine Peso", localizedName: "フィリピンペソ", flagCode: "ph", region: .asia),
        CurrencyInfo(code: "MYR", name: "Malaysian Ringgit", localizedName: "マレーシアリンギット", flagCode: "my", region: .asia),
        CurrencyInfo(code: "IDR", name: "Indonesian Rupiah", localizedName: "インドネシアルピア", flagCode: "id", region: .asia),
        CurrencyInfo(code: "INR", name: "Indian Rupee", localizedName: "インドルピー", flagCode: "in", region: .asia),

        // Western Europe
        CurrencyInfo(code: "EUR", name: "Euro", localizedName: "ユーロ", flagCode: "eu", region: .westernEurope),
        CurrencyInfo(code: "GBP", name: "British Pound", localizedName: "英ポンド", flagCode: "gb", region: .westernEurope),
        CurrencyInfo(code: "CHF", name: "Swiss Franc", localizedName: "スイスフラン", flagCode: "ch", region: .westernEurope),
        CurrencyInfo(code: "SEK", name: "Swedish Krona", localizedName: "スウェーデンクローナ", flagCode: "se", region: .westernEurope),
        CurrencyInfo(code: "NOK", name: "Norwegian Krone", localizedName: "ノルウェークローネ", flagCode: "no", region: .westernEurope),
        CurrencyInfo(code: "DKK", name: "Danish Krone", localizedName: "デンマーククローネ", flagCode: "dk", region: .westernEurope),

        // North America
        CurrencyInfo(code: "USD", name: "US Dollar", localizedName: "米ドル", flagCode: "us", region: .northAmerica),
        CurrencyInfo(code: "CAD", name: "Canadian Dollar", localizedName: "カナダドル", flagCode: "ca", region: .northAmerica),
        CurrencyInfo(code: "MXN", name: "Mexican Peso", localizedName: "メキシコペソ", flagCode: "mx", region: .northAmerica),

        // Oceania
        CurrencyInfo(code: "AUD", name: "Australian Dollar", localizedName: "豪ドル", flagCode: "au", region: .oceania),
        CurrencyInfo(code: "NZD", name: "New Zealand Dollar", localizedName: "ニュージーランドドル", flagCode: "nz", region: .oceania),
    ]

    static let defaultCurrencies: [CurrencyInfo] = [
        allCurrencies.first { $0.code == "JPY" }!,
        allCurrencies.first { $0.code == "CNY" }!,
        allCurrencies.first { $0.code == "USD" }!,
    ]

    static func find(_ code: String) -> CurrencyInfo? {
        allCurrencies.first { $0.code == code }
    }
}
