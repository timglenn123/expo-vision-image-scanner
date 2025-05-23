const { withAndroidManifest, withInfoPlist } = require("@expo/config-plugins");
import { ConfigPlugin } from 'expo/config-plugins';

const withVisionImageScannerPlugin: ConfigPlugin = config => {
    return withAndroidManifest(
        withInfoPlist(config, (config: { modResults: { manifest: { [x: string]: { $: { "android:name": string; }; }[]; }; }; }) => {
            // Add camera permission to AndroidManifest.xml
            config.modResults.manifest["uses-permission"] =
                config.modResults.manifest["uses-permission"] || [];
            config.modResults.manifest["uses-permission"].push({
                $: {
                    "android:name": "android.permission.CAMERA",
                },
            });

            return config;
        }),
        (config: { modResults: { NSCameraUsageDescription: string; }; }) => {
            // Add camera permission to iOS Info.plist
            config.modResults.NSCameraUsageDescription =
                config.modResults.NSCameraUsageDescription ||
                "This app requires access to the camera to scan documents.";

            return config;
        }
    );
};

export default withVisionImageScannerPlugin;