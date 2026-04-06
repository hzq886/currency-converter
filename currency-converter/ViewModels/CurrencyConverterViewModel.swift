import Foundation
import SwiftUI

enum KeypadKey: Hashable, Sendable {
    case digit(String)
    case decimal
    case clear
    case backspace
    case doubleZero
    case moveDown
    case add, subtract, multiply, divide, equals

    var displayLabel: String {
        switch self {
        case .digit(let d): return d
        case .decimal: return "."
        case .clear: return "C"
        case .backspace: return "←"
        case .doubleZero: return "00"
        case .moveDown: return "↓"
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        case .equals: return "="
        }
    }

    var isOperator: Bool {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return true
        default:
            return false
        }
    }
}

@Observable
class CurrencyConverterViewModel {
    // MARK: - Persistence Keys

    private static let selectedCurrenciesKey = "selectedCurrencies"
    private static let activeCurrencyIndexKey = "activeCurrencyIndex"

    // MARK: - State

    var selectedCurrencies: [CurrencyInfo]
    var activeCurrencyIndex: Int
    var calculator = CalculatorState()
    var amounts: [Decimal] = [0, 0, 0]

    var rates: [String: Double] = [:]
    var rateLastUpdated: Date?
    var rateError: String?

    var showingPicker: Bool = false
    var pickerTargetIndex: Int = 0

    var showingAddCurrency: Bool = false

    private let rateService = ExchangeRateService()

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.selectedCurrenciesKey),
           let saved = try? JSONDecoder().decode([CurrencyInfo].self, from: data),
           !saved.isEmpty {
            selectedCurrencies = saved
            amounts = Array(repeating: 0, count: saved.count)
        } else {
            selectedCurrencies = CurrencyInfo.defaultCurrencies
        }
        activeCurrencyIndex = UserDefaults.standard.integer(forKey: Self.activeCurrencyIndexKey)
        if activeCurrencyIndex >= selectedCurrencies.count {
            activeCurrencyIndex = 0
        }
    }

    // MARK: - Persistence

    private func saveCurrencies() {
        if let data = try? JSONEncoder().encode(selectedCurrencies) {
            UserDefaults.standard.set(data, forKey: Self.selectedCurrenciesKey)
        }
        UserDefaults.standard.set(activeCurrencyIndex, forKey: Self.activeCurrencyIndexKey)
    }

    // MARK: - Computed

    var rateInfoText: String {
        guard !rates.isEmpty, selectedCurrencies.count >= 3 else { return "Loading rates..." }

        let first = selectedCurrencies[0]
        let others = [selectedCurrencies[1], selectedCurrencies[2]]

        guard let firstRate = rates[first.code] else { return "Loading rates..." }

        let parts: [String] = others.compactMap { currency in
            guard let targetRate = rates[currency.code] else { return nil }
            let rate = targetRate / firstRate
            return "1 \(first.code) = \(formatRate(rate)) \(currency.code)"
        }

        return parts.joined(separator: " | ")
    }

    var timeAgoText: String {
        guard let updated = rateLastUpdated else { return "" }
        let interval = Date().timeIntervalSince(updated)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    // MARK: - Actions

    func onKeyPress(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            calculator.inputDigit(d)
        case .decimal:
            calculator.inputDecimal()
        case .clear:
            calculator.clear()
        case .backspace:
            calculator.backspace()
        case .doubleZero:
            calculator.inputDigit("0")
            calculator.inputDigit("0")
        case .moveDown:
            moveActiveCurrencyDown()
        case .add:
            calculator.inputOperator(.add)
        case .subtract:
            calculator.inputOperator(.subtract)
        case .multiply:
            calculator.inputOperator(.multiply)
        case .divide:
            calculator.inputOperator(.divide)
        case .equals:
            calculator.calculate()
        }
        updateConversions()
    }

    func updateConversions() {
        let activeAmount = calculator.displayValue
        let activeCurrency = selectedCurrencies[activeCurrencyIndex]

        guard !rates.isEmpty else { return }

        // Convert through USD base
        let activeRateToUSD: Double
        if activeCurrency.code == "USD" {
            activeRateToUSD = 1.0
        } else {
            guard let rate = rates[activeCurrency.code], rate > 0 else { return }
            activeRateToUSD = 1.0 / rate
        }

        let amountInUSD = NSDecimalNumber(decimal: activeAmount).doubleValue * activeRateToUSD

        for i in 0..<selectedCurrencies.count {
            if i == activeCurrencyIndex {
                amounts[i] = activeAmount
            } else {
                let targetCode = selectedCurrencies[i].code
                let targetRate = rates[targetCode] ?? 1.0
                let converted = amountInUSD * targetRate
                amounts[i] = Decimal(converted)
            }
        }
    }

    func moveActiveCurrencyDown() {
        let count = selectedCurrencies.count
        guard count >= 2 else { return }
        let i = activeCurrencyIndex

        if i < count - 1 {
            selectedCurrencies.swapAt(i, i + 1)
            amounts.swapAt(i, i + 1)
            activeCurrencyIndex = i + 1
        } else {
            let currency = selectedCurrencies.remove(at: i)
            selectedCurrencies.insert(currency, at: 0)
            let amount = amounts.remove(at: i)
            amounts.insert(amount, at: 0)
            activeCurrencyIndex = 0
        }
        saveCurrencies()
    }

    func setActiveCurrency(_ index: Int) {
        guard index != activeCurrencyIndex else { return }
        activeCurrencyIndex = index
        calculator.clear()
        let currentAmount = amounts[index]
        if currentAmount != 0 {
            calculator = CalculatorState()
            // Use the same 2-decimal formatting as the display to avoid precision changes
            let formatted = formatDisplayAmount(currentAmount)
            for char in formatted where char != "," {
                if char == "." {
                    calculator.inputDecimal()
                } else {
                    calculator.inputDigit(String(char))
                }
            }
        }
        saveCurrencies()
    }

    func selectCurrency(_ currency: CurrencyInfo, for index: Int) {
        guard index < selectedCurrencies.count else { return }
        selectedCurrencies[index] = currency
        showingPicker = false
        updateConversions()
        saveCurrencies()
    }

    func openPicker(for index: Int) {
        pickerTargetIndex = index
        showingPicker = true
    }

    // MARK: - Networking

    func fetchRates() async {
        rateError = nil

        do {
            let result = try await rateService.fetchRates()
            rates = result.rates
            rateLastUpdated = result.timestamp
            updateConversions()
        } catch {
            rateError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func formatDisplayAmount(_ value: Decimal) -> String {
        let doubleVal = NSDecimalNumber(decimal: value).doubleValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        if abs(doubleVal) > 0 && abs(doubleVal) < 0.01 {
            formatter.maximumFractionDigits = 6
        }
        return formatter.string(from: NSNumber(value: doubleVal)) ?? "0"
    }

    private func formatRate(_ rate: Double) -> String {
        String(format: "%.2f", rate)
    }
}
