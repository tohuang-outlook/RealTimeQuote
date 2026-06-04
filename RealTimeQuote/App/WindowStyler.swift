import AppKit
import SwiftUI

enum WindowStyler {
    static let widgetTopBarHeight: CGFloat = 0
    static let minimumSize = CGSize(width: 700, height: 300)
    static let idealSize = CGSize(width: 760, height: 320)
    static let maximumSize = CGSize(width: 860, height: 420)
    static let defaultSize = idealSize

    static func makeRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()
                .background(QuoteBoardTheme.cardFill)

            WindowChromeConfigurator()
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
        window.contentMinSize = WindowStyler.minimumSize
        window.contentMaxSize = WindowStyler.maximumSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: WindowStyler.minimumSize)).size
        window.maxSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: WindowStyler.maximumSize)).size
        window.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
        window.isOpaque = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true

        let currentContentSize = window.contentView?.frame.size ?? window.contentLayoutRect.size
        let clampedWidth = min(max(currentContentSize.width, WindowStyler.minimumSize.width), WindowStyler.maximumSize.width)
        let clampedHeight = min(max(currentContentSize.height, WindowStyler.minimumSize.height), WindowStyler.maximumSize.height)
        if currentContentSize.width != clampedWidth || currentContentSize.height != clampedHeight {
            window.setContentSize(CGSize(width: clampedWidth, height: clampedHeight))
        }
    }
}
