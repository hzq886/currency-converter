import SwiftUI

struct CurrencyDisplayArea: View {
    @Bindable var viewModel: CurrencyConverterViewModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(viewModel.selectedCurrencies.enumerated()), id: \.element.code) { index, currency in
                CurrencyRowView(
                    currency: currency,
                    amount: viewModel.amounts[index],
                    isActive: viewModel.activeCurrencyIndex == index,
                    displayText: viewModel.activeCurrencyIndex == index
                        ? viewModel.calculator.fullDisplayText : nil,
                    onTapFlag: {
                        viewModel.openPicker(for: index)
                    }
                )
                .onTapGesture {
                    viewModel.setActiveCurrency(index)
                }
            }
        }
    }
}
