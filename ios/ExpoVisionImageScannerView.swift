import ExpoModulesCore
import VisionKit

class ExpoVisionImageScannerView: ExpoView, ExpoVisionImageScannerDelegate {
    // Make this weak to avoid retain cycle
    private weak var documentCameraViewController: ExpoVisionImageScannerController?
    let onScan = EventDispatcher()
    let onCancel: EventDispatcher = EventDispatcher()
    let onError: EventDispatcher = EventDispatcher()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true

    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Only present the scanner when we're actually added to a window
        if window != nil && documentCameraViewController == nil {
            presentDocumentScanner()
        }
    }

    // Clean up when view is removed
    deinit {
        cleanupDocumentScanner()
    }

    private func cleanupDocumentScanner() {
        // Properly remove child view controller
        if let documentVC = documentCameraViewController {
            documentVC.willMove(toParent: nil)
            documentVC.view.removeFromSuperview()
            documentVC.removeFromParent()
            documentVC.delegate = nil
            documentCameraViewController = nil
        }
    }

    private func presentDocumentScanner() {
        // Wait until we're in a window and have a parent view controller
        guard let parentViewController = findNearestViewController() else {
            print("Error: Could not find a parent view controller")
            return
        }

        // Clean up any existing scanner
        cleanupDocumentScanner()

        let documentCameraViewController = ExpoVisionImageScannerController()
        documentCameraViewController.delegate = self

        // Properly add as child view controller to handle lifecycle
        parentViewController.addChild(documentCameraViewController)

        // Add the camera view directly to our view
        documentCameraViewController.view.frame = self.bounds
        addSubview(documentCameraViewController.view)

        // Set up constraints to make the camera view fill our view
        documentCameraViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            documentCameraViewController.view.topAnchor.constraint(equalTo: topAnchor),
            documentCameraViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            documentCameraViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            documentCameraViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Make sure the camera view resizes with its container
        documentCameraViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Save reference and notify child view controller that the transition is complete
        self.documentCameraViewController = documentCameraViewController
        documentCameraViewController.didMove(toParent: parentViewController)
    }

    private func findNearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }

    func documentScanner(_ scanner: UIViewController, didScanDocuments images: [UIImage]){
        var scannedItems: [[String: Any]] = []
        scannedItems.append([
            "imageUri": images[0].pngData()?.base64EncodedString() ?? "",
            "pageIndex": 0
        ])
           // Convert to JSON and pass it to onScan
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: scannedItems, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                onScan(["data": jsonString])
            }
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }


    var style: [String: Any]? {
        didSet {
            print("applying styles: \(String(describing: style))")
            applyStyles()
        }
    }

    private func applyStyles() {
        guard let style = style else { return }
        if let backgroundColor = style["backgroundColor"] as? UIColor {
            self.backgroundColor = backgroundColor
        }

        print("inside applyStyles with style: \(style)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var newFrame = self.frame

            // Default to full screen if width/height not found
            let screenBounds = UIScreen.main.bounds

            // Height
            if let heightValue = style["height"] {
                if let height = heightValue as? CGFloat {
                    newFrame.size.height = height
                } else if let heightStr = heightValue as? String, heightStr.hasSuffix("%"),
                          let percent = Double(heightStr.dropLast()),
                          let superview = self.superview {
                    newFrame.size.height = superview.frame.height * CGFloat(percent) / 100.0
                }
            } else {
                newFrame.size.height = screenBounds.height
            }

            // Width
            if let widthValue = style["width"] {
                if let width = widthValue as? CGFloat {
                    newFrame.size.width = width
                } else if let widthStr = widthValue as? String, widthStr.hasSuffix("%"),
                          let percent = Double(widthStr.dropLast()),
                          let superview = self.superview {
                    newFrame.size.width = superview.frame.width * CGFloat(percent) / 100.0
                }
            } else {
                newFrame.size.width = screenBounds.width
            }

            // Only update frame if it actually changed
            if self.frame != newFrame {
                self.frame = newFrame
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
            print(self.frame.size.width)
            print(self.frame.size.height)

            // Apply position styles
            if let top = style["top"] as? CGFloat {
                self.frame.origin.y = top
            }
            if let left = style["left"] as? CGFloat {
                self.frame.origin.x = left
            }

            // Handle right position (relative to parent)
            if let right = style["right"] as? CGFloat, let superview = self.superview {
                self.frame.origin.x = superview.frame.width - self.frame.width - right
            }

            // Handle bottom position (relative to parent)
            if let bottom = style["bottom"] as? CGFloat, let superview = self.superview {
                self.frame.origin.y = superview.frame.height - self.frame.height - bottom
            }

            // Apply size to document camera view controller if present
            if let documentVC = self.documentCameraViewController {
                documentVC.view.frame = self.bounds
                documentVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
        }
    }
    func documentScannerDidCancel(_ scanner: UIViewController){
        print("Document scanning canceled.")
        onCancel(["data": "Document scanning canceled."])
}

    func documentCameraViewController(_ scanner: UIViewController, didFailWithError error: Error) {
        print("Document scanning failed with error: \(error.localizedDescription)")
        onError(["error": "Document scanning failed with error: \(error.localizedDescription)"])
}
}
