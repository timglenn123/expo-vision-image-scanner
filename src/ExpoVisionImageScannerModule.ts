import { NativeModule, requireNativeModule } from 'expo';
import { ExpoVisionImageScannerModuleEvents } from './ExpoVisionImageScanner.types';

declare class ExpoVisionImageScannerModule extends NativeModule<ExpoVisionImageScannerModuleEvents> {
  // Define the methods and properties of the native module here
  // For example:
  // scanImage: (imageUri: string) => Promise<string>;
  // Event emitter method
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoVisionImageScannerModule>('ExpoVisionImageScannerView');
