import { ViewProps } from 'react-native';
import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

export type OnScanEvent = {
  data: string;
};

export type Props = {
  onScan?: (event: { nativeEvent: OnScanEvent }) => void;
  enabled?: boolean;
  style?: {
    backgroundColor?: string;
    borderRadius?: number;
    borderWidth?: number;
    borderColor?: string;
    width?: number;
    height?: number;
    top?: number;
    left?: number;
    right?: number;
    bottom?: number;
  };
} & ViewProps;

const NativeView: React.ComponentType<Props> = requireNativeViewManager('ExpoVisionImageScannerView');

export default function ExpoVisionImageScannerView(props: Props) {
  return (<NativeView {...props} />);
}
