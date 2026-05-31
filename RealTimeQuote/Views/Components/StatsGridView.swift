import SwiftUI

struct StatsGridView: View {
    struct Item: Equatable {
        let label: String
        let value: String
    }

    let items: [Item]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: QuoteBoardTheme.controlSpacing) {
                statCards
            }

            VStack(spacing: QuoteBoardTheme.controlSpacing) {
                statCards
            }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        ForEach(items, id: \.label) { item in
            statCard(item: item)
        }
    }

    private func statCard(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(QuoteBoardTheme.tertiaryText)

            Text(item.value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            QuoteBoardTheme.panelFill,
            in: RoundedRectangle(cornerRadius: QuoteBoardTheme.panelCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuoteBoardTheme.panelCornerRadius, style: .continuous)
                .stroke(QuoteBoardTheme.panelStroke, lineWidth: 1)
        )
    }
}
