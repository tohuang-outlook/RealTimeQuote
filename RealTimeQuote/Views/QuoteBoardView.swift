import SwiftUI

struct QuoteBoardView: View {
    @ObservedObject var viewModel: QuoteBoardViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Text(viewModel.snapshot.displaySymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text(viewModel.selectedExchange.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
