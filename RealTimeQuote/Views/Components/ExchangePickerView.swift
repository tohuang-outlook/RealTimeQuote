import SwiftUI

struct ExchangePickerView: View {
    @Binding var selection: ExchangeID

    var body: some View {
        VStack(alignment: .leading, spacing: QuoteBoardTheme.compactSpacing) {
            Text("Exchange")
                .font(QuoteBoardTheme.regularFont(size: 11))
                .foregroundStyle(QuoteBoardTheme.secondaryText)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(ExchangeID.allCases) { exchange in
                    Button {
                        selection = exchange
                    } label: {
                        Text(exchange.displayName)
                            .font(QuoteBoardTheme.regularFont(size: 13))
                            .foregroundStyle(exchange == selection ? Color.white : QuoteBoardTheme.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(exchange == selection ? Color.accentColor : Color.white.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(exchange == selection ? Color.accentColor.opacity(0.9) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
