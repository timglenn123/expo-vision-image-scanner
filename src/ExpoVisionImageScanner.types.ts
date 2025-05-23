export type ExpoVisionImageScannerModuleEvents = {
  onScan: (params: ScanEventPayload) => void;
};

export type ScanEventPayload = {
  data: string;
};

