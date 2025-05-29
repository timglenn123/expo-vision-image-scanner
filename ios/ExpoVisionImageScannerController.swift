//
//  ExpoVisionImageScannerController.swift
//  Pods
//
//  Created by Timothy Glenn on 5/24/25.
//

import UIKit
import AVFoundation
import Vision
import CoreImage

protocol ExpoVisionImageScannerDelegate: AnyObject {
    func documentScanner(_ scanner: UIViewController, didScanDocuments images: [UIImage])
    func documentScannerDidCancel(_ scanner: UIViewController)
    func documentCameraViewController(_ scanner: UIViewController, didFailWithError error: Error)
}

class ExpoVisionImageScannerController: UIViewController {

    weak var delegate: ExpoVisionImageScannerDelegate?
    var maxScans: Int = 1

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var overlayLayer: CAShapeLayer!
    private var gridLayer: CAShapeLayer!
    private var detectionHighlighted = false

    private var scannedImages: [UIImage] = []
    private var lastDetectedRectangle: VNRectangleObservation?
    private var stableDetectionCount = 0
    private let requiredStableDetections = 3
    private var lastDetectionTime: TimeInterval = 0
    private let detectionThrottleInterval: TimeInterval = 0.1

    // UI Elements
    private var cancelButton: UIButton!
    private var flashButton: UIButton!
    private var autoButton: UIButton!
    private var captureButton: UIButton!
    private var counterLabel: UILabel!
    private var bottomBar: UIView!
    private var isFlashOn = false
    private var isProcessing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        setupOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCamera()
    }

    private func setupUI() {
        view.backgroundColor = .black

        // Cancel button (top-left)
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        // Flash button (top-center)
        flashButton = UIButton(type: .system)
        flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)

        // Capture button (bottom-center) inside a black bar
        bottomBar = UIView()
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false


        captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.masksToBounds = true
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.lightGray.cgColor

        // Add an inner circle to create a border effect
        let borderCircle = UIView()
        borderCircle.isUserInteractionEnabled = false
        borderCircle.layer.cornerRadius = 35
        borderCircle.layer.borderWidth = 4
        borderCircle.layer.borderColor = UIColor.white.cgColor
        borderCircle.backgroundColor = .clear
        borderCircle.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addSubview(borderCircle)
        NSLayoutConstraint.activate([
            borderCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            borderCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            borderCircle.widthAnchor.constraint(equalTo: captureButton.widthAnchor),
            borderCircle.heightAnchor.constraint(equalTo: captureButton.heightAnchor)
        ])

        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(captureButton)




        // Add to view
        [cancelButton, flashButton, bottomBar].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0!)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Flash button
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            flashButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),

            // Add bottomBar constraints
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 120),

            // Center captureButton horizontally in bottomBar
            captureButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -28),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)

        ])
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showError("Camera not available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

        } catch {
            showError("Camera setup failed: \(error.localizedDescription)")
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    private func setupOverlay() {
        overlayLayer = CAShapeLayer()
        overlayLayer.strokeColor = UIColor.blue.cgColor
        overlayLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        overlayLayer.lineWidth = 3

        // Insert overlayLayer below the bottomBar's layer
        if let bottomBarLayer = view.subviews.last?.layer {
            view.layer.insertSublayer(overlayLayer, below: bottomBarLayer)
        } else {
            view.layer.addSublayer(overlayLayer)
        }

        // Grid layer for internal grid animation
        gridLayer = CAShapeLayer()
        gridLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 1
        gridLayer.opacity = 0

        // Insert gridLayer below the bottomBar's layer
        if let bottomBarLayer = view.subviews.last?.layer {
            view.layer.insertSublayer(gridLayer, below: bottomBarLayer)
        } else {
            view.layer.addSublayer(gridLayer)
        }
    }

    private func startCamera() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    private func stopCamera() {
        captureSession.stopRunning()
    }

    @objc private func cancelTapped() {
        delegate?.documentScannerDidCancel(self)
    }

    @objc private func flashTapped() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                isFlashOn.toggle()
                device.torchMode = isFlashOn ? .on : .off
                device.unlockForConfiguration()

                let imageName = isFlashOn ? "bolt" : "bolt.slash"
                flashButton.setImage(UIImage(systemName: imageName), for: .normal)
            } catch {
                print("Flash error: \(error)")
            }
        }
    }

    @objc private func captureTapped() {
        guard !isProcessing else { return }
        guard scannedImages.count < maxScans else { return }

        isProcessing = true
        captureButton.isEnabled = false

        let settings = AVCapturePhotoSettings()
        if isFlashOn, photoOutput.supportedFlashModes.contains(.on) {
            settings.flashMode = .on
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    //
    //    private func updateCounter() {
    //        counterLabel.text = "\(scannedImages.count)/\(maxScans)"
    //    }
    //
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// MARK: - Document Detection
extension ExpoVisionImageScannerController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        // Throttle detection requests
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastDetectionTime >= detectionThrottleInterval else { return }
        lastDetectionTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectDocumentSegmentationRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("Document detection error: \(error)")
                return
            }

            guard let observations = request.results as? [VNRectangleObservation],
                  let rectangle = observations.first else {
                DispatchQueue.main.async {
                    self.clearOverlay()
                }
                return
            }

            // Check if detection is stable
            if let lastRect = self.lastDetectedRectangle {
                let similarity = self.calculateSimilarity(rect1: lastRect, rect2: rectangle)
                if similarity > 0.95 { // 95% similarity threshold
                    self.stableDetectionCount += 1
                } else {
                    self.stableDetectionCount = 0
                }
            } else {
                self.stableDetectionCount = 0
            }

            self.lastDetectedRectangle = rectangle

            // Only show overlay if detection is stable
            if self.stableDetectionCount >= self.requiredStableDetections {
                let firstStable = (self.stableDetectionCount == self.requiredStableDetections)
                DispatchQueue.main.async {
                    self.drawDetectedRectangle(rectangle)
                    if firstStable && !self.detectionHighlighted {
                        self.animateDetectionFound(rectangle)
                        self.detectionHighlighted = true
                    }
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform document detection: \(error)")
        }
    }

    private func calculateSimilarity(rect1: VNRectangleObservation, rect2: VNRectangleObservation) -> Double {
        let points1 = [rect1.topLeft, rect1.topRight, rect1.bottomLeft, rect1.bottomRight]
        let points2 = [rect2.topLeft, rect2.topRight, rect2.bottomLeft, rect2.bottomRight]

        var totalDistance: Double = 0
        for i in 0..<4 {
            let dx = points1[i].x - points2[i].x
            let dy = points1[i].y - points2[i].y
            totalDistance += sqrt(dx * dx + dy * dy)
        }

        return max(0, 1 - totalDistance) // Convert distance to similarity
    }

    private func drawDetectedRectangle(_ rectangle: VNRectangleObservation) {
        // Convert Vision normalized image coordinates to preview layer coordinates
        func convert(_ point: CGPoint) -> CGPoint {
            // Vision origin is bottom-left, invert Y to match capture coordinate space
            let metadataPoint = CGPoint(x: point.x, y: 1 - point.y)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: metadataPoint)
        }

        // Convert corner points (invert Y for proper mapping)
        let topLeft = convert(rectangle.topLeft)
        let topRight = convert(rectangle.topRight)
        let bottomLeft = convert(rectangle.bottomLeft)
        let bottomRight = convert(rectangle.bottomRight)

        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()

        // Animate the path change smoothly
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = overlayLayer.path
        animation.toValue = path.cgPath
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        overlayLayer.add(animation, forKey: "pathAnimation")
        overlayLayer.path = path.cgPath

        // If grid is active, update its path to follow the moving rectangle
        if detectionHighlighted {
            let gridPath = UIBezierPath()
            let subdivisions = 4
            // Vertical lines
            for i in 1..<subdivisions {
                let t = CGFloat(i) / CGFloat(subdivisions)
                let start = CGPoint(x: topLeft.x + (bottomLeft.x - topLeft.x) * t,
                                    y: topLeft.y + (bottomLeft.y - topLeft.y) * t)
                let end   = CGPoint(x: topRight.x + (bottomRight.x - topRight.x) * t,
                                    y: topRight.y + (bottomRight.y - topRight.y) * t)
                gridPath.move(to: start)
                gridPath.addLine(to: end)
            }
            // Horizontal lines
            for i in 1..<subdivisions {
                let t = CGFloat(i) / CGFloat(subdivisions)
                let start = CGPoint(x: topLeft.x + (topRight.x - topLeft.x) * t,
                                    y: topLeft.y + (topRight.y - topLeft.y) * t)
                let end   = CGPoint(x: bottomLeft.x + (bottomRight.x - bottomLeft.x) * t,
                                    y: bottomLeft.y + (bottomRight.y - bottomLeft.y) * t)
                gridPath.move(to: start)
                gridPath.addLine(to: end)
            }
            gridLayer.path = gridPath.cgPath
        }
    }

    private func clearOverlay() {
        // Animate the overlay disappearing
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        overlayLayer.add(animation, forKey: "fadeOutAnimation")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.overlayLayer.path = nil
            self.overlayLayer.opacity = 1.0
            self.overlayLayer.removeAllAnimations()
            // Clear grid overlay and reset highlight state
            self.gridLayer.path = nil
            self.gridLayer.opacity = 0
            self.gridLayer.removeAllAnimations()
            self.detectionHighlighted = false
        }

        lastDetectedRectangle = nil
        stableDetectionCount = 0
    }

    /// Animate an internal grid and brighten edges on first stable detection
    private func animateDetectionFound(_ rectangle: VNRectangleObservation) {
        // Convert Vision normalized coordinates to preview layer coordinates
        func convert(_ point: CGPoint) -> CGPoint {
            let metadataPoint = CGPoint(x: point.x, y: 1 - point.y)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: metadataPoint)
        }

        // Corner points
        let tl = convert(rectangle.topLeft)
        let tr = convert(rectangle.topRight)
        let bl = convert(rectangle.bottomLeft)
        let br = convert(rectangle.bottomRight)

        // Build internal grid path
        let gridPath = UIBezierPath()
        let subdivisions = 4
        // Vertical lines
        for i in 1..<subdivisions {
            let t = CGFloat(i) / CGFloat(subdivisions)
            let start = CGPoint(x: tl.x + (bl.x - tl.x) * t,
                                y: tl.y + (bl.y - tl.y) * t)
            let end   = CGPoint(x: tr.x + (br.x - tr.x) * t,
                                y: tr.y + (br.y - tr.y) * t)
            gridPath.move(to: start)
            gridPath.addLine(to: end)
        }
        // Horizontal lines
        for i in 1..<subdivisions {
            let t = CGFloat(i) / CGFloat(subdivisions)
            let start = CGPoint(x: tl.x + (tr.x - tl.x) * t,
                                y: tl.y + (tr.y - tl.y) * t)
            let end   = CGPoint(x: bl.x + (br.x - bl.x) * t,
                                y: bl.y + (br.y - bl.y) * t)
            gridPath.move(to: start)
            gridPath.addLine(to: end)
        }

        gridLayer.path = gridPath.cgPath

        // Fade in grid
        let gridFade = CABasicAnimation(keyPath: "opacity")
        gridFade.fromValue = 0
        gridFade.toValue = 0.5
        gridFade.duration = 0.4
        gridFade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gridFade.fillMode = .forwards
        gridFade.isRemovedOnCompletion = false
        gridLayer.add(gridFade, forKey: "fadeInGrid")
        gridLayer.opacity = 0.8

        // Brighten border color briefly
        let borderBrighten = CABasicAnimation(keyPath: "strokeColor")
        borderBrighten.fromValue = overlayLayer.strokeColor
        borderBrighten.toValue = UIColor.white.cgColor
        borderBrighten.duration = 0.5
        borderBrighten.autoreverses = true
        borderBrighten.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        overlayLayer.add(borderBrighten, forKey: "brightenBorders")
    }
}

// MARK: - Photo Capture
extension ExpoVisionImageScannerController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.captureButton.isEnabled = true
            }
        }

        guard error == nil else {
            DispatchQueue.main.async {
                self.showError("Failed to capture photo: \(error!.localizedDescription)")
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.showError("Failed to process captured image")
            }
            return
        }

        // Perform fresh document detection on the captured image and crop accordingly
        DispatchQueue.global(qos: .userInitiated).async {
            let cropped = self.autoCropImage(image)
            DispatchQueue.main.async {
                self.scannedImages.append(cropped)
                if self.scannedImages.count >= self.maxScans {
                    self.delegate?.documentScanner(self, didScanDocuments: self.scannedImages)
                }
            }
        }
    }

    // Detect and crop the document from the captured UIImage using Vision on the final image
    private func autoCropImage(_ image: UIImage) -> UIImage {
        // Extract CGImage and apply its orientation
        guard let cgInput = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgInput, options: [.applyOrientationProperty: true])
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        // Perform document detection on the oriented CIImage
        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Auto-crop detection error: \(error)")
            return image
        }
        guard let rectangle = request.results?.first as? VNRectangleObservation else { return image }

        // Map normalized points to image coordinates in CIImage space
        let topLeft = CGPoint(x: rectangle.topLeft.x * width, y: rectangle.topLeft.y * height)
        let topRight = CGPoint(x: rectangle.topRight.x * width, y: rectangle.topRight.y * height)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * width, y: rectangle.bottomLeft.y * height)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * width, y: rectangle.bottomRight.y * height)

        // Apply perspective correction to the CIImage
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return image }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        guard let outputCI = filter.outputImage else { return image }

        // Render the corrected image and return a new UIImage
        let context = CIContext()
        guard let outputCG = context.createCGImage(outputCI, from: outputCI.extent) else { return image }
        return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
    }
}
