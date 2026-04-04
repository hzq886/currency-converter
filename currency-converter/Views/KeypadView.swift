import SwiftUI

struct KeypadView: View {
    let onKey: (KeypadKey) -> Void

    private let rows: [[KeypadKey]] = [
        [.clear, .backspace, .moveDown, .divide],
        [.digit("7"), .digit("8"), .digit("9"), .multiply],
        [.digit("4"), .digit("5"), .digit("6"), .subtract],
        [.digit("1"), .digit("2"), .digit("3"), .add],
        [.doubleZero, .digit("0"), .decimal, .equals],
    ]

    var body: some View {
        VStack(spacing: AppTheme.keypadSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: AppTheme.keypadSpacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                        KeypadButton(key: key) {
                            onKey(key)
                        }
                    }
                }
            }
        }
    }
}
