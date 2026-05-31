import SwiftUI

enum QuoteBoardTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.08, green: 0.08, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardFill = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let cardStroke = Color.white.opacity(0.10)
    static let cardShadow = Color.black.opacity(0.35)
    static let panelFill = Color.white.opacity(0.045)
    static let panelStroke = Color.white.opacity(0.08)
    static let badgeFill = Color.white.opacity(0.05)
    static let secondaryText = Color.white.opacity(0.55)
    static let tertiaryText = Color.white.opacity(0.45)
    static let primaryText = Color.white.opacity(0.92)
    static let errorText = Color(red: 1.0, green: 0.52, blue: 0.52)
    static let positive = Color(red: 0.25, green: 0.88, blue: 0.56)
    static let caution = Color(red: 1.0, green: 0.76, blue: 0.24)
    static let negative = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let neutral = Color.white.opacity(0.72)

    static let cardCornerRadius: CGFloat = 28
    static let panelCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12
    static let outerPadding: CGFloat = 18
    static let contentHorizontalPadding: CGFloat = 28
    static let contentVerticalPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 22
    static let controlSpacing: CGFloat = 14
    static let compactSpacing: CGFloat = 8
}

struct QuoteBoardPresentationState: Equatable {
    let header: PriceHeaderView.Content
    let stats: [StatsGridView.Item]
    let connectionState: ConnectionState
    let lastSelectionError: String?

    init(snapshot: QuoteSnapshot, lastSelectionError: String?) {
        header = PriceHeaderView.Content(
            symbol: snapshot.displaySymbol,
            exchangeName: snapshot.exchange.displayName,
            priceText: Self.currencyText(snapshot.lastPrice),
            changeText: Self.changeText(absolute: snapshot.absoluteChange, percent: snapshot.percentChange),
            updatedAtText: Self.updatedAtText(snapshot.updatedAt),
            changeTone: Self.changeTone(snapshot.absoluteChange)
        )
        stats = [
            StatsGridView.Item(label: "24H HIGH", value: Self.currencyText(snapshot.high24h)),
            StatsGridView.Item(label: "24H LOW", value: Self.currencyText(snapshot.low24h)),
            StatsGridView.Item(label: "24H VOL", value: Self.volumeText(snapshot.volume24h))
        ]
        self.connectionState = snapshot.connectionState
        self.lastSelectionError = lastSelectionError
    }

    private static func changeTone(_ absoluteChange: Decimal?) -> PriceHeaderView.ChangeTone {
        guard let absoluteChange else { return .neutral }
        if absoluteChange > 0 { return .positive }
        if absoluteChange < 0 { return .negative }
        return .neutral
    }

    private static func currencyText(_ value: Decimal?) -> String {
        guard let value else { return "--" }
        return currencyFormatter.string(from: value as NSDecimalNumber) ?? "--"
    }

    private static func volumeText(_ value: Decimal?) -> String {
        guard let value else { return "--" }
        return volumeFormatter.string(from: value as NSDecimalNumber) ?? "--"
    }

    private static func changeText(absolute: Decimal?, percent: Decimal?) -> String {
        guard let absolute, let percent else { return "Awaiting 24h change" }
        let absoluteText = currencyFormatter.string(from: absolute as NSDecimalNumber) ?? "--"
        let percentText = percentFormatter.string(from: percent as NSDecimalNumber) ?? "--"
        let signPrefix = absolute > 0 ? "+" : ""
        return "\(signPrefix)\(absoluteText) (\(percentText))"
    }

    private static func updatedAtText(_ updatedAt: Date?) -> String {
        guard let updatedAt else { return "Waiting for live market data" }
        return "Updated \(timeFormatter.string(from: updatedAt))"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positiveSuffix = "%"
        formatter.negativeSuffix = "%"
        return formatter
    }()

    private static let volumeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()
}

struct QuoteBoardView: View {
    @ObservedObject var viewModel: QuoteBoardViewModel

    var body: some View {
        let presentation = QuoteBoardPresentationState(
            snapshot: viewModel.snapshot,
            lastSelectionError: viewModel.lastSelectionError
        )

        ZStack {
            QuoteBoardTheme.backgroundGradient
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                .fill(QuoteBoardTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                        .stroke(QuoteBoardTheme.cardStroke, lineWidth: 1)
                )
                .shadow(color: QuoteBoardTheme.cardShadow, radius: 24, y: 16)
                .padding(QuoteBoardTheme.outerPadding)

            VStack(alignment: .leading, spacing: QuoteBoardTheme.sectionSpacing) {
                HStack(alignment: .top, spacing: QuoteBoardTheme.controlSpacing) {
                    ExchangePickerView(selection: exchangeSelection)
                    TradingPairPickerView(selection: pairSelection)
                    Spacer(minLength: 0)
                    ConnectionBadgeView(state: presentation.connectionState)
                }

                PriceHeaderView(content: presentation.header)
                StatsGridView(items: presentation.stats)

                if let lastSelectionError = presentation.lastSelectionError {
                    Text(lastSelectionError)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(QuoteBoardTheme.errorText)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, QuoteBoardTheme.contentHorizontalPadding)
            .padding(.vertical, QuoteBoardTheme.contentVerticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var exchangeSelection: Binding<ExchangeID> {
        Binding(
            get: { viewModel.selectedExchange },
            set: { viewModel.selectExchange($0) }
        )
    }

    private var pairSelection: Binding<TradingPair> {
        Binding(
            get: { viewModel.selectedPair },
            set: { viewModel.selectPair($0) }
        )
    }
}
