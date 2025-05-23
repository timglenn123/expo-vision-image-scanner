import { VisionView } from 'expo-vision-image-scanner';
import { OnScanEvent } from 'expo-vision-image-scanner/ExpoVisionImageScannerView';
import { useState } from 'react';
import { View, Image, Button, StyleSheet } from 'react-native';

export default function App() {
  const styles = StyleSheet.create({
    container: {
      flex: 1,
    },
    scanner: {
      flex: 1,
    },
    resultContainer: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      padding: 20,
    },
    image: {
      width: '100%',
      height: '50%',
      marginBottom: 20,
    },
  });
  const [scannedImage, setScannedImage] = useState<string | null>(null);

  const handleReset = () => {
    setScannedImage(null);
  };

  function handleScan(event: { nativeEvent: OnScanEvent; }): void {
    //console.log('Scan result:', event.nativeEvent.data);
    // Convert base64 to image source format
    const data= JSON.parse(event.nativeEvent.data);
    const processedImage= `data:image/png;base64,${data[0].imageUri}`;
    setScannedImage(processedImage);
  }

  return (
    <View style={styles.container}>
      {!scannedImage ? (
        <VisionView style={styles.scanner} onScan={handleScan} />
      ) : (
        <View style={styles.resultContainer}>
          <Image
            source={{ uri: scannedImage }}
            style={styles.image}
            resizeMode="contain"
          />
          <Button title="Scan Again" onPress={handleReset} />
        </View>
      )}
    </View>
  );

}

