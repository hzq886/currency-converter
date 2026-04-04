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

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        return f
    }()

    var body: some View {
        Text(date.map { Self.formatter.string(from: $0) } ?? "")
            .font(.system(size: 11))
            .foregroundColor(AppTheme.textSecondary)
    }
}
