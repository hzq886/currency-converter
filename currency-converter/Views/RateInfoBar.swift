import SwiftUI

struct RateInfoBar: View {
    @Bindable var viewModel: CurrencyConverterViewModel

    var body: some View {
        HStack(spacing: 8) {
            Text(viewModel.rateInfoText)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            TimeAgoText(date: viewModel.rateLastUpdated)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct TimeAgoText: View {
    let date: Date?

    private var text: String {
        guard let date = date else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(AppTheme.textSecondary)
    }
}
