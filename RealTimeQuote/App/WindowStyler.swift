import SwiftUI

enum WindowStyler {
    static let minimumSize = CGSize(width: 500, height: 250)
    static let idealSize = CGSize(width: 560, height: 280)
    static let maximumSize = CGSize(width: 640, height: 320)
    static let defaultSize = idealSize

    static func makeRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(
                minWidth: minimumSize.width,
                idealWidth: idealSize.width,
                maxWidth: maximumSize.width,
                minHeight: minimumSize.height,
                idealHeight: idealSize.height,
                maxHeight: maximumSize.height
            )
            .background(.black)
    }
}
