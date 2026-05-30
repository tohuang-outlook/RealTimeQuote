import SwiftUI

struct QuoteBoardView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}
