//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS)
import LinkPresentation
import UIKit

/// A SwiftUI wrapper for `UIActivityViewController`.
@MainActor
struct ActivityShareSheet: UIViewControllerRepresentable {
    /// The activity items presented in the sheet.
    let activityItems: [Any]

    /// Creates the UIKit view controller.
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    /// Updates the UIKit view controller.
    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

/// Provides share sheet preview metadata for images.
final class ActivityImageItemSource: NSObject, UIActivityItemSource {
    /// The shared image to present.
    private let image: UIImage

    /// The preview title shown in the share sheet.
    private let title: String

    /// Creates a new image item source.
    ///
    /// - Parameters:
    ///   - image: The image to share.
    ///   - title: The preview title for the share sheet.
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    /// Provides a placeholder object for the activity controller.
    ///
    /// - Parameter activityViewController: The activity controller requesting the placeholder.
    /// - Returns: The placeholder image.
    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        image
    }

    /// Provides the image to share for the selected activity type.
    ///
    /// - Parameters:
    ///   - activityViewController: The activity controller requesting the item.
    ///   - activityType: The selected activity type.
    /// - Returns: The image to share.
    func activityViewController(
        _: UIActivityViewController,
        itemForActivityType _: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    /// Provides link metadata for richer previews.
    ///
    /// - Parameter activityViewController: The activity controller requesting metadata.
    /// - Returns: Link metadata with image preview.
    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}
#endif
