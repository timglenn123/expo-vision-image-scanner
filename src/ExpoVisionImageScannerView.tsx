import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoVisionImageScannerViewProps } from './ExpoVisionImageScanner.types';

const NativeView: React.ComponentType<ExpoVisionImageScannerViewProps> =
  requireNativeView('ExpoVisionImageScanner');

export default function ExpoVisionImageScannerView(props: ExpoVisionImageScannerViewProps) {
  return <NativeView {...props} />;
}
