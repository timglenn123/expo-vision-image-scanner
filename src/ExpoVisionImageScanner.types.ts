export type ExpoVisionImageScannerModuleEvents = {
  onScan: (params: ScanEventPayload) => void;
  onCancel: (params: { data: string }) => void;
  onError: (params: { error: string }) => void;
};

export type ScanEventPayload = {
  data: string;
};

