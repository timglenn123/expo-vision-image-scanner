import { registerWebModule, NativeModule } from 'expo';

import { ExpoVisionImageScannerModuleEvents } from './ExpoVisionImageScanner.types';

class ExpoVisionImageScannerModule extends NativeModule<ExpoVisionImageScannerModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoVisionImageScannerModule, 'ExpoVisionImageScannerModule');
