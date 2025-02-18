//
//  Scanner.swift
//  NoteBlocks App
//
//  Created by Deyan on 18.02.25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        let metadataOutput = AVCaptureMetadataOutput()

        guard let videoCaptureDevice = videoCaptureDevice,
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return viewController
        }

        captureSession.addInput(videoInput)
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = viewController.view.layer.bounds
        viewController.view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let scannedUsername = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.onScan(scannedUsername) // Return the scanned username
                }
            }
        }
    }
}

