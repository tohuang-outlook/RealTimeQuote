import SwiftUI

struct ExchangePickerView: View {
    @Binding var selection: ExchangeID

    var body: some View {
        VStack(alignment: .leading, spacing: QuoteBoardTheme.compactSpacing) {
            Text("Exchange")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
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
