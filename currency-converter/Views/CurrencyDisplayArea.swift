import SwiftUI

struct CurrencyDisplayArea: View {
    @Bindable var viewModel: CurrencyConverterViewModel
    @State private var draggedCurrency: CurrencyInfo?

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(viewModel.selectedCurrencies.enumerated()), id: \.element.code) { index, currency in
                CurrencyRowView(
                    currency: currency,
                    amount: viewModel.amounts[index],
                    isActive: viewModel.activeCurrencyIndex == index,
                    displayText: viewModel.activeCurrencyIndex == index
                        ? viewModel.calculator.displayText : nil,
                    expressionText: viewModel.activeCurrencyIndex == index
                        ? viewModel.calculator.expressionText : nil,
                    onTapFlag: {
                        viewModel.openPicker(for: index)
                    }
                )
                .onTapGesture {
                    viewModel.setActiveCurrency(index)
                }
                .draggable(currency.code) {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardBackground)
                        .frame(height: 60)
                        .overlay(
                            HStack {
                                FlagImageView(countryCode: currency.flagCode)
                                Text(currency.code)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        )
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let droppedCode = items.first,
                          let sourceIndex = viewModel.selectedCurrencies.firstIndex(where: { $0.code == droppedCode }),
                          sourceIndex != index else { return false }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.moveCurrency(from: sourceIndex, to: index)
                    }
                    return true
                }
            }
        }
    }
}
