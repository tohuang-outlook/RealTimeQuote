import SwiftUI

struct StatsGridView: View {
    struct Item: Equatable {
        let label: String
        let value: String
        let valueColor: Color
    }

    let items: [Item]
    let spacing: CGFloat
    let numberOfColumns: Int

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 110), spacing: spacing, alignment: .leading),
            count: numberOfColumns
        )

        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            ForEach(items, id: \.label) { item in
                marketField(item: item)
            }
        }
    }

    private func marketField(item: Item) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(item.label)
                .font(QuoteBoardTheme.regularFont(size: 12))
                .foregroundStyle(QuoteBoardTheme.secondaryText)

            Spacer(minLength: 6)

            Text(item.value)
                .font(QuoteBoardTheme.regularFont(size: 17))
                .foregroundStyle(item.valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
