import ExpoModulesCore

public class ExpoVisionImageScannerModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ExpoVisionImageScannerView")
        View(ExpoVisionImageScannerView.self) {
            // Make sure this name matches exactly with what's used in the JS side
            // Add your view props and events here
            Events("onScan")
            Events("onCancel")
            Events("onError")
            Prop("enabled") { (view: ExpoVisionImageScannerView, enabled: Bool) in
                if(enabled) {

                    view.isHidden = false
                } else {

                    view.isHidden = true
                }
            }

           // Add style props
           Prop("style") { (view: ExpoVisionImageScannerView, style: [String: Any]) in
               view.style = style
           }
            }

        }
    }

