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
    let heroPriceFontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(content.symbol)
                    .font(QuoteBoardTheme.boldFont(size: 18))
                    .foregroundStyle(QuoteBoardTheme.primaryText)

                Text(content.exchangeName)
                    .font(QuoteBoardTheme.regularFont(size: 12))
                    .foregroundStyle(QuoteBoardTheme.tertiaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(QuoteBoardTheme.badgeFill, in: Capsule())
            }

            Text(content.priceText)
                .font(QuoteBoardTheme.heavyFont(size: heroPriceFontSize))
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(content.changeText)
                .font(QuoteBoardTheme.regularFont(size: 16))
                .foregroundStyle(trendColor)

            Text(content.updatedAtText)
                .font(QuoteBoardTheme.regularFont(size: 12))
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
