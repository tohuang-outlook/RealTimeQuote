import SwiftUI

struct TradingPairPickerView: View {
    @Binding var selection: TradingPair

    var body: some View {
        VStack(alignment: .leading, spacing: QuoteBoardTheme.compactSpacing) {
            Text("Pair")
                .font(QuoteBoardTheme.regularFont(size: 11))
                .foregroundStyle(Color.white.opacity(0.72))
                .textCase(.uppercase)

            HStack(spacing: 6) {
                ForEach(TradingPair.allCases) { pair in
                    Button {
                        selection = pair
                    } label: {
                        Text(pair.displaySymbol)
                            .font(QuoteBoardTheme.regularFont(size: 13))
                            .foregroundStyle(pair == selection ? Color.white : QuoteBoardTheme.primaryText)
                            .frame(width: 78)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(pair == selection ? Color.white.opacity(0.10) : Color.white.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(pair == selection ? Color.white.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
