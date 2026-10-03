import SwiftUI

struct RoutePreviewPanel: View {
    let previewState: RoutePreviewState
    let previewSegments: [ResolvedTripSegment]
    let googleMapsAPIKey: String?
    let googleMapsMapID: String?
    let replayToken: UInt64
    let errorMessage: String?
    let onReplay: () -> Void
    let onRendererEvent: (RoutePreviewRendererEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Preview")
                        .font(.title2.bold())
                        .foregroundStyle(QuoteBoardTheme.primaryText)

                    Text(statusDescription)
                        .font(QuoteBoardTheme.regularFont(size: 13))
                        .foregroundStyle(QuoteBoardTheme.secondaryText)
                }

                Spacer()

                RendererStatusBadge(previewState: previewState)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(QuoteBoardTheme.regularFont(size: 13))
                    .foregroundStyle(QuoteBoardTheme.errorText)
            }

            if !previewSegments.isEmpty {
                Button("Replay") {
                    onReplay()
                }
                .buttonStyle(.bordered)
                .disabled(previewState == .idle)
            }

            RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                .fill(QuoteBoardTheme.cardFill)
                .overlay {
                    if !previewSegments.isEmpty {
                        RoutePreviewWebView(
                            segments: previewSegments,
                            googleMapsAPIKey: googleMapsAPIKey,
                            googleMapsMapID: googleMapsMapID,
                            onRendererEvent: onRendererEvent,
                            replayToken: replayToken
                        )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: QuoteBoardTheme.cardCornerRadius,
                                    style: .continuous
                                )
                            )
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: previewIconName)
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(QuoteBoardTheme.primaryText)

                            Text(previewHeadline)
                                .font(.headline)
                                .foregroundStyle(QuoteBoardTheme.primaryText)
                        }
                        .padding(24)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                        .stroke(QuoteBoardTheme.cardStroke, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                .fill(QuoteBoardTheme.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                .stroke(QuoteBoardTheme.panelStroke, lineWidth: 1)
        )
    }

    private var statusDescription: String {
        switch previewState {
        case .idle:
            return "Add cities and generate a preview to prepare the renderer."
        case .resolving:
            return "Resolving route data for the next preview."
        case let .ready(segments):
            return "\(segments.count) segment\(segments.count == 1 ? "" : "s") ready for export."
        case .failed:
            return "The renderer needs updated trip data before previewing."
        }
    }

    private var previewHeadline: String {
        switch previewState {
        case .idle:
            return "Preview will appear here"
        case .resolving:
            return "Resolving route"
        case let .ready(segments):
            return "Ready with \(segments.count) segment\(segments.count == 1 ? "" : "s")"
        case .failed:
            return "Preview unavailable"
        }
    }

    private var previewIconName: String {
        switch previewState {
        case .idle:
            return "globe.americas"
        case .resolving:
            return "point.3.connected.trianglepath.dotted"
        case .ready:
            return "checkmark.seal"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}
