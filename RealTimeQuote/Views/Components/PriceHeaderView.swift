import SwiftUI

struct PriceHeaderView: View {
    enum ChangeTone: Equatable {
        case positive
        case negative
        case neutral
    }

    struct Content: Equatable {
        let symbol: String
        let exchangeName: String
        let priceText: String
        let changeText: String
        let updatedAtText: String
        let changeTone: ChangeTone
    }

    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(content.symbol)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(QuoteBoardTheme.primaryText)

                Text(content.exchangeName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuoteBoardTheme.tertiaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(QuoteBoardTheme.badgeFill, in: Capsule())
            }

            Text(content.priceText)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(content.changeText)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(trendColor)

            Text(content.updatedAtText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(QuoteBoardTheme.tertiaryText)
        }
    }

    private var trendColor: Color {
        switch content.changeTone {
        case .positive:
            return QuoteBoardTheme.positive
        case .negative:
            return QuoteBoardTheme.negative
        case .neutral:
            return QuoteBoardTheme.neutral
        }
    }
}
