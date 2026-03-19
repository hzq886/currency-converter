import SwiftUI

struct FlagImageView: View {
    let countryCode: String
    var size: CGFloat = AppTheme.flagSize

    var body: some View {
        AsyncImage(url: URL(string: "https://flagcdn.com/w160/\(countryCode).png")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                fallbackView
            case .empty:
                Circle()
                    .fill(AppTheme.buttonBackground)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(AppTheme.textSecondary)
                    )
            @unknown default:
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallbackView: some View {
        Circle()
            .fill(AppTheme.buttonBackground)
            .overlay(
                Text(countryCode.uppercased())
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            )
    }
}
