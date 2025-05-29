# expo-vision-image-scanner

Use Vision Camera to Scan Documents

# API documentation

- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/vision-image-scanner/)
- [Documentation for the main branch](https://docs.expo.dev/versions/unversioned/sdk/vision-image-scanner/)

## Usage

```jsx
import { ExpoVisionImageScannerView } from 'expo-vision-image-scanner';

export default function App() {
  return (
    <ExpoVisionImageScannerView
      style={{
        width: 300,
        height: 400,
        top: 100,
        left: 20,
      }}
      onScan={(event) => {
        console.log('Scanned document:', event.data);
      }}
      onError={(error) => {
        console.error('Scan error:', error);
      }}
      onCancel={() => {
        console.log('Scan cancelled');
      }}
    />
  );
}
```

## Props

### `style`

Accepts standard View style props plus the following specific styles:
- `width`: number - Width of the scanner view
- `height`: number - Height of the scanner view
- `top`: number - Distance from the top of the parent view
- `left`: number - Distance from the left of the parent view
- `right`: number - Distance from the right of the parent view
- `bottom`: number - Distance from the bottom of the parent view
- `backgroundColor`: string - Background color of the scanner view

### Events

#### `onScan`
Callback that fires when a document is successfully scanned. Receives an event object with:
- `data`: string - Base64 encoded string of the scanned image

```typescript
type ScanResult = {
  data: string; // Base64 encoded image data
}
```

#### `onError`
Callback that fires when an error occurs during scanning. Receives the error object.

#### `onCancel`
Callback that fires when the user cancels the scanning process.

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install expo-vision-image-scanner
```

### Configure for Android




### Configure for iOS

Run `npx pod-install` after installing the npm package.

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).
