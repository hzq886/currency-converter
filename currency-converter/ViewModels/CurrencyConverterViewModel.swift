import Foundation
import SwiftUI

enum KeypadKey: Hashable, Sendable {
    case digit(String)
    case decimal
    case clear
    case backspace
    case doubleZero
    case swap
    case add, subtract, multiply, divide, equals

    var displayLabel: String {
        switch self {
        case .digit(let d): return d
        case .decimal: return "."
        case .clear: return "C"
        case .backspace: return "←"
        case .doubleZero: return "00"
        case .swap: return "↑↓"
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
    // MARK: - State

    var selectedCurrencies: [CurrencyInfo] = CurrencyInfo.defaultCurrencies
    var activeCurrencyIndex: Int = 0
    var calculator = CalculatorState()
    var amounts: [Decimal] = [0, 0, 0]

    var rates: [String: Double] = [:]
    var rateLastUpdated: Date?
    var rateError: String?

    var showingPicker: Bool = false
    var pickerTargetIndex: Int = 0

    var showingAddCurrency: Bool = false

    private let rateService = ExchangeRateService()

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
        case .swap:
            swapCurrencies()
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

    func swapCurrencies() {
        guard selectedCurrencies.count >= 2 else { return }
        selectedCurrencies.swapAt(0, 1)
        amounts.swapAt(0, 1)

        if activeCurrencyIndex == 0 {
            activeCurrencyIndex = 1
        } else if activeCurrencyIndex == 1 {
            activeCurrencyIndex = 0
        }
    }

    func setActiveCurrency(_ index: Int) {
        guard index != activeCurrencyIndex else { return }
        activeCurrencyIndex = index
        calculator.clear()
        let currentAmount = amounts[index]
        if currentAmount != 0 {
            calculator = CalculatorState()
            let formatted = calculator.formatNumber(currentAmount)
            // Re-enter the converted amount as the starting point
            for char in formatted where char != "," {
                if char == "." {
                    calculator.inputDecimal()
                } else {
                    calculator.inputDigit(String(char))
                }
            }
        }
    }

    func selectCurrency(_ currency: CurrencyInfo, for index: Int) {
        guard index < selectedCurrencies.count else { return }
        selectedCurrencies[index] = currency
        showingPicker = false
        updateConversions()
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

    private func formatRate(_ rate: Double) -> String {
        String(format: "%.2f", rate)
    }
}
