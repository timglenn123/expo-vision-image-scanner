import { VisionView } from 'expo-vision-image-scanner';
import { OnScanEvent, OnCancelEvent } from 'expo-vision-image-scanner/ExpoVisionImageScannerView';
import { useState } from 'react';
import { View, Image, Button, StyleSheet, Text } from 'react-native';

export default function App() {
  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: 'black',
    },
    scanner: {
      width:'100%',
      height:'100%',
      top: 0,
      left: 0,
      backgroundColor: 'black',
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
    text: {
      color: '#FFF',
      position: 'absolute',
      bottom: 40,
      left: 20,
      right: 20,
      textAlign: 'center',
    },
  });
  const [scannedImage, setScannedImage] = useState<string | null>(null);

  const handleReset = () => {
    setScannedImage(null);
    console.log('Scanner reset');
  };

  const handleCancel = (event: { nativeEvent: OnCancelEvent; }) => {
    console.log('Scan cancelled:', event.nativeEvent.data);
    setScannedImage("No image scanned");

  };

  function handleScan(event: { nativeEvent: OnScanEvent; }): void {
    try {
      const data = JSON.parse(event.nativeEvent.data);
      if (Array.isArray(data) && data[0]?.imageUri) {
        const processedImage = `data:image/png;base64,${data[0].imageUri}`;
        setScannedImage(processedImage);
      } else {
        console.error('Unexpected data format:', data);
      }
    } catch (error) {
      console.error('Error parsing scan data:', error);
    }
  }

  return (
    <View style={styles.container}>
      {!scannedImage ? (
        <VisionView style={styles.scanner} onScan={handleScan} onCancel={handleCancel} />
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

