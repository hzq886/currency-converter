import SwiftUI
import Combine

struct RateInfoBar: View {
    @Bindable var viewModel: CurrencyConverterViewModel
    @State private var rotationAngle: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    await viewModel.refreshRates()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.accent)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .buttonStyle(.plain)
            .onChange(of: viewModel.isLoadingRates) { _, isLoading in
                if isLoading {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                } else {
                    withAnimation(.default) {
                        rotationAngle = 0
                    }
                }
            }

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
    @State private var text: String = ""

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(AppTheme.textSecondary)
            .onAppear { updateText() }
            .onChange(of: date) { _, _ in updateText() }
            .onReceive(
                Timer.publish(every: 30, on: .main, in: .common).autoconnect()
            ) { _ in
                updateText()
            }
    }

    private func updateText() {
        guard let date = date else {
            text = ""
            return
        }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            text = "just now"
        } else if interval < 3600 {
            text = "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            text = "\(Int(interval / 3600))h ago"
        } else {
            text = "\(Int(interval / 86400))d ago"
        }
    }
}
