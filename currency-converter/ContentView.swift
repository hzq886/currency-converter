import SwiftUI

struct ContentView: View {
    @State private var viewModel = CurrencyConverterViewModel()

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Currency display area
                CurrencyDisplayArea(viewModel: viewModel)
                    .padding(.horizontal, 4)

                // Rate info bar
                RateInfoBar(viewModel: viewModel)
                    .padding(.top, 4)

                // Divider
                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 0.5)
                    .padding(.horizontal, 20)

                // Keypad
                KeypadView { key in
                    viewModel.onKeyPress(key)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showingPicker) {
            CurrencyPickerView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchRates()
        }
    }
}

#Preview {
    ContentView()
}
