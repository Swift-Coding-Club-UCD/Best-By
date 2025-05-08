//
//  ScannerView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI
import Vision
import UIKit

// MARK: - ScannerView
struct ScannerView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Binding var image: UIImage?
    @Binding var detectedName: String
    @Binding var detectedDate: String
    
    let useCamera: Bool
    
    @State private var expirationDate = ""
    @State private var showPicker = false
    @State private var showSourceSelection = true
    @State private var scanStatus: ScanStatus = .idle
    @State private var selectedSource: ImageSource = .camera
    @Environment(\.presentationMode) var presentationMode
    
    enum ScanStatus {
        case idle, scanning, success, failed, noDateFound
        
        var description: String {
            switch self {
            case .idle: return ""
            case .scanning: return "Scanning..."
            case .success: return "Scan successful!"
            case .failed: return "Scan failed. Please try again."
            case .noDateFound: return "No expiration date found. Try another image or enter manually."
            }
        }
        
        var color: Color {
            switch self {
            case .idle: return .clear
            case .scanning: return .yellow
            case .success: return .green
            case .failed, .noDateFound: return .red
            }
        }
    }
    
    enum ImageSource {
        case camera, photoLibrary
        
        var title: String {
            switch self {
            case .camera: return "Camera"
            case .photoLibrary: return "Photo Library"
            }
        }
        
        var icon: String {
            switch self {
            case .camera: return "camera.fill"
            case .photoLibrary: return "photo.on.rectangle.angled"
            }
        }
        
        var sourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .photoLibrary: return .photoLibrary
            }
        }
    }
    
    init(useCamera: Bool, image: Binding<UIImage?>, detectedName: Binding<String>, detectedDate: Binding<String>) {
        self.useCamera = useCamera
        self._image = image
        self._detectedName = detectedName
        self._detectedDate = detectedDate
        self._selectedSource = State(initialValue: useCamera ? .camera : .photoLibrary)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showSourceSelection && image == nil {
                    sourceSelectionView
                } else {
                    scannerContentView
                }
            }
            .navigationTitle("Scan Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: image != nil ? Button("Retake") {
                    image = nil
                    expirationDate = ""
                    scanStatus = .idle
                    showSourceSelection = true
                } : nil
            )
            .sheet(isPresented: $showPicker) {
                ScannerImagePicker(
                    sourceType: selectedSource.sourceType
                ) { img in
                    self.image = img
                    recognizeText(in: img)
                    showSourceSelection = false
                }
            }
        }
    }
    
    private var sourceSelectionView: some View {
        VStack(spacing: 25) {
            Text("Choose Image Source")
                .font(.headline)
                .padding(.top, 30)
            
            Spacer()
            
            ForEach([ImageSource.camera, ImageSource.photoLibrary], id: \.title) { source in
                Button(action: {
                    selectedSource = source
                    showPicker = true
                }) {
                    VStack(spacing: 15) {
                        Image(systemName: source.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text(source.title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                }
                .padding(.horizontal)
                .disabled(source == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera))
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var scannerContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image display
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.top)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 300)
                        .overlay(Text("No Image Selected").foregroundColor(.secondary))
                        .cornerRadius(10)
                        .padding(.top)
                }
                
                // Scan status and results
                if scanStatus != .idle {
                    statusView
                }
                
                if !expirationDate.isEmpty && scanStatus == .success {
                    resultView
                }
                
                // Action buttons
                actionButtonsView
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if image != nil && expirationDate.isEmpty {
                recognizeText(in: image!)
            }
        }
    }
    
    private var statusView: some View {
        HStack {
            if scanStatus == .scanning {
                ProgressView()
                    .padding(.trailing, 5)
            }
            
            Text(scanStatus.description)
                .font(.subheadline)
                .foregroundColor(scanStatus.color)
        }
        .padding()
        .background(scanStatus.color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var resultView: some View {
        VStack(spacing: 16) {
            Group {
                if !detectedName.isEmpty && detectedName != "Scanning..." {
                    Text("Detected Product:")
                        .font(.headline)
                    
                    Text(detectedName)
                        .font(.title3)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text("Expiration Date:")
                    .font(.headline)
                
                Text(expirationDate.replacingOccurrences(of: "EXP: ", with: ""))
                    .font(.title2)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 15) {
            if scanStatus == .success {
                Button(action: {
                    // Transfer the extracted date to the binding
                    detectedDate = expirationDate.replacingOccurrences(of: "EXP: ", with: "")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Use Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            } else if scanStatus == .failed || scanStatus == .noDateFound {
                Button(action: {
                    if let img = image {
                        recognizeText(in: img)
                    }
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if scanStatus != .idle && scanStatus != .scanning {
                Button(action: {
                    image = nil
                    expirationDate = ""
                    scanStatus = .idle
                    showSourceSelection = true
                }) {
                    Text("New Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if scanStatus == .failed || scanStatus == .noDateFound {
                Button(action: {
                    // Just dismiss and let user enter data manually
                    if !detectedName.isEmpty && detectedName != "Scanning..." {
                        // Keep the detected name if available
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Enter Manually")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Text Recognition
    private func recognizeText(in image: UIImage) {
        scanStatus = .scanning
        expirationDate = ""
        
        guard let cgImage = image.cgImage else { 
            scanStatus = .failed
            return 
        }

        let request = VNRecognizeTextRequest { req, error in
            guard let observations = req.results as? [VNRecognizedTextObservation],
                  error == nil else {
                DispatchQueue.main.async { 
                    self.scanStatus = .failed
                }
                return
            }

            let dates = observations.compactMap { obs in
                obs.topCandidates(1).first?.string.extractExpirationDate()
            }

            // Extract product name first since it doesn't depend on finding dates
            self.extractProductName(from: observations)
            
            DispatchQueue.main.async {
                if let bestDate = dates.first {
                    self.expirationDate = "EXP: \(bestDate.uppercased())"
                    self.scanStatus = .success
                } else {
                    self.expirationDate = ""
                    self.scanStatus = .noDateFound
                }
            }
        }

        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0.01
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.scanStatus = .failed
                }
            }
        }
    }
    
    private func extractProductName(from observations: [VNRecognizedTextObservation]) {
        // Simple extraction logic - look for longer strings that aren't dates
        let possibleNames = observations.compactMap { obs -> String? in
            let text = obs.topCandidates(1).first?.string ?? ""
            if text.count > 3 && !text.contains("/") && !text.lowercased().contains("exp") {
                return text
            }
            return nil
        }
        
        DispatchQueue.main.async {
            if let name = possibleNames.first {
                self.detectedName = name
            }
        }
    }
}

// MARK: - ImagePicker
struct ScannerImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiVC: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ScannerImagePicker
        init(_ parent: ScannerImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            picker.dismiss(animated: true)
            if let img = info[.originalImage] as? UIImage {
                parent.completion(img)
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - String ExpirationDate Helper
/// Parses an expiration date string in DD/MM/YY, MM/DD/YY, MM/YY or MM-YYYY format and validates it is not in the past.
extension String {
    func extractExpirationDate() -> String? {
        // Pattern for both DD/MM/YY and MM/YY formats
        let pattern = #"(0?[1-9]|[12][0-9]|3[01])?[/\-]?(0[1-9]|1[0-2])[/\-](\d{2}|\d{4})"#
        guard let range = self.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let found = String(self[range]).replacingOccurrences(of: "-", with: "/")
        let parts = found.split(separator: "/").map(String.init)
        
        // Handle different formats
        var day = "01"
        var month: String
        var yearPart: String
        
        if parts.count == 3 {
            // DD/MM/YY format
            day = parts[0].count == 1 ? "0\(parts[0])" : parts[0]
            month = parts[1]
            yearPart = parts[2]
        } else if parts.count == 2 {
            // MM/YY format
            month = parts[0]
            yearPart = parts[1]
        } else {
            return nil
        }
        
        // Validate month
        guard let monthInt = Int(month), (1...12).contains(monthInt) else {
            return nil
        }
        
        // Format month with leading zero if needed
        if month.count == 1 {
            month = "0\(month)"
        }
        
        // Handle year format
        let year = yearPart.count == 4 ? String(yearPart.suffix(2)) : yearPart
        
        // Validate the date is not in the past
        let now = Date(), cal = Calendar.current
        let currentDay = cal.component(.day, from: now)
        let currentMonth = cal.component(.month, from: now)
        let currentYear = cal.component(.year, from: now) % 100
        
        guard let yy = Int(year),
              yy > currentYear || 
              (yy == currentYear && monthInt > currentMonth) ||
              (yy == currentYear && monthInt == currentMonth && Int(day) ?? 1 >= currentDay) else {
            return nil
        }

        return "\(day)/\(month)/\(year)"
    }
}
