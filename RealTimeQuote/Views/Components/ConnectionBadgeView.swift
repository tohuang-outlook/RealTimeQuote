import SwiftUI

struct ConnectionBadgeView: View {
    let state: ConnectionState

    var body: some View {
        Label {
            Text(labelText)
                .font(QuoteBoardTheme.regularFont(size: 12))
        } icon: {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
        }
        .foregroundStyle(QuoteBoardTheme.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(QuoteBoardTheme.badgeFill, in: Capsule())
        .overlay(
            Capsule()
                .stroke(badgeColor.opacity(0.4), lineWidth: 1)
        )
        .fixedSize()
    }

    private var labelText: String {
        switch state {
        case .connecting:
            return "Connecting"
        case .live:
            return "Live"
        case .reconnecting:
            return "Reconnecting"
        case .disconnected(let issue):
            return issue == .remoteClosed ? "Disconnected" : "Offline"
        }
    }

    private var badgeColor: Color {
        switch state {
        case .connecting, .reconnecting:
            return QuoteBoardTheme.caution
        case .live:
            return QuoteBoardTheme.positive
        case .disconnected:
            return QuoteBoardTheme.negative
        }
    }
}
