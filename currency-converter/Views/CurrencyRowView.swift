import SwiftUI

struct CurrencyRowView: View {
    let currency: CurrencyInfo
    let amount: Decimal
    let isActive: Bool
    let displayText: String?
    let expressionText: String?
    let onTapFlag: () -> Void

    private var formattedAmount: String {
        let nsDecimal = amount as NSDecimalNumber
        let doubleVal = nsDecimal.doubleValue

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        // For very small non-zero values, show more decimals
        if abs(doubleVal) > 0 && abs(doubleVal) < 0.01 {
            formatter.maximumFractionDigits = 6
        }

        return formatter.string(from: NSNumber(value: doubleVal)) ?? "0"
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTapFlag) {
                FlagImageView(countryCode: currency.flagCode)
            }
            .buttonStyle(.plain)

            Text(currency.code)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 36, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let expression = expressionText, !expression.isEmpty, isActive {
                    Text(expression)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Text(isActive ? (displayText ?? "0") : formattedAmount)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(isActive ? AppTheme.cardBackground : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
