import SwiftUI

struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    @State private var isPressed = false

    private var foregroundColor: Color {
        switch key {
        case .clear:
            return AppTheme.accent
        case .add, .subtract, .multiply, .divide, .equals:
            return .white
        default:
            return AppTheme.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch key {
        case .equals:
            return AppTheme.accentBright
        case .add, .subtract, .multiply, .divide:
            return AppTheme.accent
        default:
            return AppTheme.buttonBackground
        }
    }

    private var pressedColor: Color {
        switch key {
        case .equals:
            return AppTheme.accent
        case .add, .subtract, .multiply, .divide:
            return AppTheme.accentBright
        default:
            return AppTheme.buttonPressed
        }
    }

    var body: some View {
        Button(action: action) {
            Text(key.displayLabel)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(foregroundColor)
                .frame(width: AppTheme.keypadButtonSize, height: AppTheme.keypadButtonSize)
                .background(
                    Circle()
                        .fill(isPressed ? pressedColor : backgroundColor)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 3, y: 3)
                        .shadow(color: .white.opacity(0.03), radius: 4, x: -2, y: -2)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
