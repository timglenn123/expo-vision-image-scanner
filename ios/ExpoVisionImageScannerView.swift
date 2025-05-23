import ExpoModulesCore
import VisionKit

class ExpoVisionImageScannerView: ExpoView, VNDocumentCameraViewControllerDelegate {
    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        presentDocumentScanner()
    }
    
    let onScan = EventDispatcher()
    
    var isEnabled = true;
    
    private func presentDocumentScanner() {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController else {
            print("Unable to access root view controller.")
            return
        }

        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        topViewController.present(documentCameraViewController, animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true, completion: nil)
        var scannedItems: [[String: Any]] = []
        
        if(scan.pageCount==1){
            let scannedImage = scan.imageOfPage(at: 0)
            scannedItems.append([
                "imageUri": scannedImage.pngData()?.base64EncodedString() ?? "",
                "pageIndex": 0
            ])
            sendEvent(scannedItems)
        }else{
            for pageIndex in 0..<scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                // Append the scanned image data to the array
                scannedItems.append([
                    "imageUri": scannedImage.pngData()?.base64EncodedString() ?? "",
                    "pageIndex": pageIndex
                ])
            }
            sendEvent(scannedItems)
        }
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
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
        print("Document scanning canceled.")
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true, completion: nil)
        print("Document scanning failed with error: \(error.localizedDescription)")
    }
}
