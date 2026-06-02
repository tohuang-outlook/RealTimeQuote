import SwiftUI

struct TradingPairPickerView: View {
    @Binding var selection: TradingPair

    var body: some View {
        VStack(alignment: .leading, spacing: QuoteBoardTheme.compactSpacing) {
            Text("Pair")
                .font(QuoteBoardTheme.regularFont(size: 11))
                .foregroundStyle(QuoteBoardTheme.secondaryText)
                .textCase(.uppercase)

            Picker("Trading Pair", selection: $selection) {
                ForEach(TradingPair.allCases) { pair in
                    Text(pair.displaySymbol).tag(pair)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(minWidth: 130)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                QuoteBoardTheme.badgeFill,
                in: RoundedRectangle(cornerRadius: QuoteBoardTheme.controlCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QuoteBoardTheme.controlCornerRadius, style: .continuous)
                    .stroke(QuoteBoardTheme.panelStroke, lineWidth: 1)
            )
        }
    }
}
