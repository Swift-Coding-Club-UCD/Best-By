//
//  BarcodeScanner.swift
//  fridge
//
//  Created by Claude on 7/2/25.
//

import SwiftUI
import AVFoundation

struct BarcodeScanner: View {
    @Binding var scannedBarcode: String
    @Binding var isShowingScanner: Bool
    
    var body: some View {
        ZStack {
            BarcodeScannerVC(scannedBarcode: $scannedBarcode, isShowingScanner: $isShowingScanner)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        isShowingScanner = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .foregroundColor(.white)
                    }
                    .padding([.top, .leading], 30)
                    
                    Spacer()
                }
                
                Spacer()
                
                Text("Scan Product Barcode")
                    .font(.headline)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
            }
        }
    }
}

struct BarcodeScannerVC: UIViewControllerRepresentable {
    @Binding var scannedBarcode: String
    @Binding var isShowingScanner: Bool
    
    func makeUIViewController(context: Context) -> BarcodeReaderViewController {
        let viewController = BarcodeReaderViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: BarcodeReaderViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BarcodeReaderViewControllerDelegate {
        var parent: BarcodeScannerVC
        
        init(_ parent: BarcodeScannerVC) {
            self.parent = parent
        }
        
        func didFindBarcode(barcode: String) {
            parent.scannedBarcode = barcode
            parent.isShowingScanner = false
        }
    }
}

protocol BarcodeReaderViewControllerDelegate: AnyObject {
    func didFindBarcode(barcode: String)
}

class BarcodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeReaderViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128, .code39, .code93, .upce]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Add scanning area indicator
        let scanRect = CGRect(x: view.bounds.width * 0.2, 
                              y: view.bounds.height * 0.4,
                              width: view.bounds.width * 0.6, 
                              height: view.bounds.height * 0.2)
        
        let scanAreaView = UIView(frame: scanRect)
        scanAreaView.layer.borderColor = UIColor.white.cgColor
        scanAreaView.layer.borderWidth = 2
        scanAreaView.backgroundColor = UIColor.clear
        view.addSubview(scanAreaView)
        
        // Start session in background to avoid freezing the UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFindBarcode(barcode: stringValue)
        }
    }
} 