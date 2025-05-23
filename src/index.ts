// Reexport the native module. On web, it will be resolved to ExpoVisionImageScannerModule.web.ts
// and on native platforms to ExpoVisionImageScannerModule.ts
export { default } from './ExpoVisionImageScannerModule';
export { default as ExpoVisionImageScannerView } from './ExpoVisionImageScannerView';
export * from  './ExpoVisionImageScanner.types';
