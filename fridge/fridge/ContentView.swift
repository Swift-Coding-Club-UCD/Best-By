//
//  ContentView.swift
//  fridge
//
//  Created by Aktan Azat on 4/15/25.
//

import SwiftUI
import Vision
import UIKit

struct ContentView: View {
    @State private var image: UIImage?
    @State private var expirationDate = ""
    @State private var showPicker = false
    @State private var useCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 300)
                        .overlay(Text("No Image Selected").foregroundColor(.secondary))
                        .cornerRadius(8)
                }

                HStack {
                    Button("Select Photo") {
                        useCamera = false
                        showPicker = true
                    }
                    Button("Take Photo") {
                        useCamera = true
                        showPicker = true
                    }
                }

                // Results Display
                if !expirationDate.isEmpty {
                    VStack {
                        Text("Expiration Date:")
                            .font(.headline)
                        Text(expirationDate)
                            .font(.title2)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                } else if image != nil {
                    Text("No valid expiration date found")
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Expiry Scanner")
            .sheet(isPresented: $showPicker) {
                ImagePicker(
                    sourceType: useCamera ? .camera : .library
                ) { img in
                    self.image = img
                    recognizeText(in: img)
                }
            }
        }
    }

    // MARK: - Text Recognition
    func recognizeText(in image: UIImage) {
        expirationDate = "Scanning..."
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { req, error in
            guard let observations = req.results as? [VNRecognizedTextObservation],
                  error == nil else {
                DispatchQueue.main.async { self.expirationDate = "Scan failed" }
                return
            }

            let dates = observations.compactMap { obs in
                obs.topCandidates(1).first?.string.extractExpirationDate()
            }

            DispatchQueue.main.async {
                if let bestDate = dates.first {
                    self.expirationDate = "EXP: \(bestDate.uppercased())"
                } else {
                    self.expirationDate = "No valid date found"
                }
            }
        }

        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0.01
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, library }
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void

    init(sourceType: Source, completion: @escaping (UIImage) -> Void) {
        self.sourceType = sourceType == .camera ? .camera : .photoLibrary
        self.completion = completion
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiVC: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

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

// #Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
