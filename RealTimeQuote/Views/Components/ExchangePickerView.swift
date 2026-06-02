import SwiftUI

struct ExchangePickerView: View {
    @Binding var selection: ExchangeID

    var body: some View {
        VStack(alignment: .leading, spacing: QuoteBoardTheme.compactSpacing) {
            Text("Exchange")
                .font(QuoteBoardTheme.regularFont(size: 11))
                .foregroundStyle(QuoteBoardTheme.secondaryText)
                .textCase(.uppercase)

            Picker("Exchange", selection: $selection) {
                ForEach(ExchangeID.allCases) { exchange in
                    Text(exchange.displayName).tag(exchange)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 180)
        }
    }
}
