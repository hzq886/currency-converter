import Foundation

struct CalculatorState {
    enum Operator: String {
        case add = "+"
        case subtract = "−"
        case multiply = "×"
        case divide = "÷"
    }

    private(set) var displayText: String = "0"
    private(set) var expressionText: String = ""
    private var currentValue: Decimal = 0
    private var pendingOperator: Operator?
    private var pendingOperand: Decimal = 0
    private var isEnteringNumber: Bool = false
    private var hasDecimalPoint: Bool = false
    private var justCalculated: Bool = false

    var displayValue: Decimal {
        Decimal(string: displayText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    // MARK: - Input

    mutating func inputDigit(_ digit: String) {
        if justCalculated {
            clear()
        }

        if !isEnteringNumber {
            displayText = digit == "0" ? "0" : digit
            isEnteringNumber = digit != "0"
        } else {
            let raw = displayText.replacingOccurrences(of: ",", with: "")
            if raw.count >= 12 { return }
            displayText = raw + digit
        }
        isEnteringNumber = true
        formatDisplay()
    }

    mutating func inputDecimal() {
        if justCalculated {
            clear()
        }

        if !isEnteringNumber {
            displayText = "0."
            isEnteringNumber = true
            hasDecimalPoint = true
            return
        }

        if !hasDecimalPoint {
            displayText = displayText.replacingOccurrences(of: ",", with: "") + "."
            hasDecimalPoint = true
        }
    }

    mutating func inputOperator(_ op: Operator) {
        justCalculated = false
        let value = displayValue

        if isEnteringNumber, let pending = pendingOperator {
            let result = perform(pending, left: pendingOperand, right: value)
            pendingOperand = result
            displayText = formatNumber(result)
            expressionText = formatNumber(result) + " " + op.rawValue
        } else {
            pendingOperand = value
            expressionText = displayText + " " + op.rawValue
        }

        pendingOperator = op
        isEnteringNumber = false
        hasDecimalPoint = false
    }

    mutating func calculate() {
        guard let op = pendingOperator else { return }
        let value = displayValue
        let result = perform(op, left: pendingOperand, right: value)

        expressionText = formatNumber(pendingOperand) + " " + op.rawValue + " " + displayText
        displayText = formatNumber(result)
        currentValue = result
        pendingOperator = nil
        pendingOperand = 0
        isEnteringNumber = false
        hasDecimalPoint = false
        justCalculated = true
    }

    mutating func clear() {
        displayText = "0"
        expressionText = ""
        currentValue = 0
        pendingOperator = nil
        pendingOperand = 0
        isEnteringNumber = false
        hasDecimalPoint = false
        justCalculated = false
    }

    mutating func backspace() {
        if !isEnteringNumber { return }

        var raw = displayText.replacingOccurrences(of: ",", with: "")
        if raw.count <= 1 || (raw.count == 2 && raw.hasPrefix("-")) {
            displayText = "0"
            isEnteringNumber = false
            hasDecimalPoint = false
            return
        }

        let removed = raw.removeLast()
        if removed == "." {
            hasDecimalPoint = false
        }
        displayText = raw
        formatDisplay()
    }

    mutating func toggleSign() {
        if displayText == "0" { return }

        var raw = displayText.replacingOccurrences(of: ",", with: "")
        if raw.hasPrefix("-") {
            raw.removeFirst()
        } else {
            raw = "-" + raw
        }
        displayText = raw
        formatDisplay()
    }

    // MARK: - Private

    private func perform(_ op: Operator, left: Decimal, right: Decimal) -> Decimal {
        switch op {
        case .add: return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide:
            if right == 0 { return 0 }
            return left / right
        }
    }

    private mutating func formatDisplay() {
        let raw = displayText.replacingOccurrences(of: ",", with: "")
        if raw.contains(".") {
            let parts = raw.split(separator: ".", maxSplits: 1)
            let intPart = String(parts[0])
            let decPart = parts.count > 1 ? String(parts[1]) : ""
            let formattedInt = formatIntegerPart(intPart)
            displayText = formattedInt + "." + decPart
        } else {
            displayText = formatIntegerPart(raw)
        }
    }

    private func formatIntegerPart(_ str: String) -> String {
        let isNegative = str.hasPrefix("-")
        let digits = isNegative ? String(str.dropFirst()) : str
        guard let number = Int64(digits) else { return str }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: number)) ?? str
        return isNegative ? "-" + formatted : formatted
    }

    func formatNumber(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let doubleVal = nsDecimal.doubleValue

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0

        // Remove trailing zeros
        if let result = formatter.string(from: NSNumber(value: doubleVal)) {
            return result
        }
        return "\(doubleVal)"
    }
}
