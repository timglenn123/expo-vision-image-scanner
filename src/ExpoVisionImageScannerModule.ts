import { NativeModule, requireNativeModule } from 'expo';

import { ExpoVisionImageScannerModuleEvents } from './ExpoVisionImageScanner.types';

declare class ExpoVisionImageScannerModule extends NativeModule<ExpoVisionImageScannerModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoVisionImageScannerModule>('ExpoVisionImageScanner');
