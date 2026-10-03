import AppKit
import SwiftUI

enum WindowStyler {
    static let widgetTopBarHeight: CGFloat = 0
    static let minimumSize = CGSize(width: 700, height: 300)
    static let idealSize = CGSize(width: 760, height: 320)
    static let maximumSize = CGSize(width: 860, height: 420)
    static let defaultSize = idealSize
    static let plannerMinimumSize = CGSize(width: 1100, height: 720)
    static let plannerIdealSize = CGSize(width: 1320, height: 860)
    static let plannerMaximumSize = CGSize(width: 1800, height: 1200)

    static func makeRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        makeSizedRootView(
            minimumSize: minimumSize,
            idealSize: idealSize,
            maximumSize: maximumSize,
            content: content
        )
    }

    static func makePlannerRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        makeSizedRootView(
            minimumSize: plannerMinimumSize,
            idealSize: plannerIdealSize,
            maximumSize: plannerMaximumSize,
            content: content
        )
    }

    private static func makeSizedRootView<Content: View>(
        minimumSize: CGSize,
        idealSize: CGSize,
        maximumSize: CGSize,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()
                .background(QuoteBoardTheme.cardFill)

            WindowChromeConfigurator(
                minimumSize: minimumSize,
                maximumSize: maximumSize
            )
                .allowsHitTesting(false)
        }
        .frame(
            minWidth: minimumSize.width,
            idealWidth: idealSize.width,
            maxWidth: maximumSize.width,
            minHeight: minimumSize.height,
            idealHeight: idealSize.height,
            maxHeight: maximumSize.height
        )
        .background(QuoteBoardTheme.cardFill)
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    let minimumSize: CGSize
    let maximumSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            applyWindowStyle(for: view)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            applyWindowStyle(for: nsView)
        }
    }

    private func applyWindowStyle(for view: NSView) {
        guard let window = view.window else { return }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.contentMinSize = minimumSize
        window.contentMaxSize = maximumSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: minimumSize)).size
        window.maxSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: maximumSize)).size
        window.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
        window.isOpaque = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true

        let currentContentSize = window.contentView?.frame.size ?? window.contentLayoutRect.size
        let clampedWidth = min(max(currentContentSize.width, minimumSize.width), maximumSize.width)
        let clampedHeight = min(max(currentContentSize.height, minimumSize.height), maximumSize.height)
        if currentContentSize.width != clampedWidth || currentContentSize.height != clampedHeight {
            window.setContentSize(CGSize(width: clampedWidth, height: clampedHeight))
        }
    }
}
