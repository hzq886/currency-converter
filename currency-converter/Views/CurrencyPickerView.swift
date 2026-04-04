import SwiftUI

struct CurrencyPickerView: View {
    @Bindable var viewModel: CurrencyConverterViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var displayedCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return CurrencyInfo.allCurrencies
        }

        let query = searchText.lowercased()
        return CurrencyInfo.allCurrencies.filter {
            $0.code.lowercased().contains(query) ||
            $0.name.lowercased().contains(query) ||
            $0.localizedName.contains(query)
        }
    }

    private var groupedCurrencies: [(region: CurrencyRegion, currencies: [CurrencyInfo])] {
        CurrencyRegion.allCases.compactMap { region in
            let currencies = displayedCurrencies.filter { $0.region == region }
            return currencies.isEmpty ? nil : (region, currencies)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    ForEach(groupedCurrencies, id: \.region) { group in
                        Section {
                            ForEach(group.currencies) { currency in
                                Button {
                                    viewModel.selectCurrency(currency, for: viewModel.pickerTargetIndex)
                                    dismiss()
                                } label: {
                                    currencyRow(currency)
                                }
                                .listRowBackground(AppTheme.cardBackground)
                            }
                        } header: {
                            Text(group.region.rawValue)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .searchable(text: $searchText, prompt: "検索")
            .navigationTitle("通貨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.accent)
                    }
                }

            }
        }
        .preferredColorScheme(.dark)
    }

    private func currencyRow(_ currency: CurrencyInfo) -> some View {
        HStack(spacing: 14) {
            FlagImageView(countryCode: currency.flagCode)

            VStack(alignment: .leading, spacing: 2) {
                Text(currency.localizedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Text(currency.code)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
