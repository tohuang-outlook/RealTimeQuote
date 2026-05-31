import SwiftUI

enum WindowStyler {
    static let minimumSize = CGSize(width: 540, height: 340)
    static let idealSize = CGSize(width: 620, height: 390)
    static let maximumSize = CGSize(width: 760, height: 460)
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
