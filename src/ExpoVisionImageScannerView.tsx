import { ViewProps } from 'react-native';
import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

export type Props = {
  url?: string;
} & ViewProps;

const NativeView: React.ComponentType<Props> = requireNativeViewManager('ExpoVisionImageScannerView');

export default function ExpoVisionImageScannerView(props: Props) {
  return <NativeView {...props} />;
}
