import SwiftUI

struct RendererStatusBadge: View {
    let previewState: RoutePreviewState

    var body: some View {
        Label(title, systemImage: iconName)
            .font(QuoteBoardTheme.regularFont(size: 12))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor)
            )
    }

    private var title: String {
        switch previewState {
        case .idle:
            return "Idle"
        case .resolving:
            return "Resolving"
        case .ready:
            return "Ready"
        case .failed:
            return "Error"
        }
    }

    private var iconName: String {
        switch previewState {
        case .idle:
            return "circle.dashed"
        case .resolving:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .ready:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private var foregroundColor: Color {
        switch previewState {
        case .idle:
            return QuoteBoardTheme.neutral
        case .resolving:
            return QuoteBoardTheme.caution
        case .ready:
            return QuoteBoardTheme.positive
        case .failed:
            return QuoteBoardTheme.errorText
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.16)
    }
}
