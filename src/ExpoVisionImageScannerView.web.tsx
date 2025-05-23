import * as React from 'react';

import { ExpoVisionImageScannerViewProps } from './ExpoVisionImageScanner.types';

export default function ExpoVisionImageScannerView(props: ExpoVisionImageScannerViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
