import ExpoModulesCore

public class ExpoVisionImageScannerModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ExpoVisionImageScannerView")
        View(ExpoVisionImageScannerView.self) {
            // Make sure this name matches exactly with what's used in the JS side
            // Add your view props and events here
            Events("onScan")

            Prop("enabled") { (view: ExpoVisionImageScannerView, enabled: Bool) in
                view.isEnabled = enabled
            }

           // Add style props
           Prop("style") { (view: ExpoVisionImageScannerView, style: [String: Any]) in
               view.style = style
           }
            }

        }
    }

