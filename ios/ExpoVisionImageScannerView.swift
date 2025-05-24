import ExpoModulesCore
import VisionKit

class ExpoVisionImageScannerView: ExpoView, ExpoVisionImageScannerDelegate {
    // Make this weak to avoid retain cycle
    private weak var documentCameraViewController: ExpoVisionImageScannerController?
    let onScan = EventDispatcher()
    var isEnabled = true
    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        presentDocumentScanner()
    }
    
    // Clean up when view is removed
    deinit {
        documentCameraViewController?.delegate = nil
    }
    
    private func presentDocumentScanner() {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController else {
            print("Unable to access root view controller.")
            return
        }
        
        let documentCameraViewController = ExpoVisionImageScannerController()
        documentCameraViewController.delegate = self
        self.documentCameraViewController = documentCameraViewController
        topViewController.present(documentCameraViewController, animated: true, completion: nil)
    }
    
    func documentScanner(_ scanner: UIViewController, didScanDocuments images: [UIImage]){
        scanner.dismiss(animated: true)
        var scannedItems: [[String: Any]] = []
        scannedItems.append([
            "imageUri": images[0].pngData()?.base64EncodedString() ?? "",
            "pageIndex": 0
        ])
        sendEvent(scannedItems)
    }
    
    func sendEvent(_ scannedItems: [[String: Any]]) {
        
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
    
    func documentScannerDidCancel(_ scanner: UIViewController){
scanner.dismiss(animated: true)
    print("Document scanning canceled.")
}

    func documentCameraViewController(_ scanner: UIViewController, didFailWithError error: Error) {
    scanner.dismiss(animated: true)
    print("Document scanning failed with error: \(error.localizedDescription)")
}
}
