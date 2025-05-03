import SwiftUI
import Vision
import UIKit

// MARK: - ScannerView Representable
/// A SwiftUI wrapper that presents a camera or photo picker and uses Vision to detect item name and expiration date.
struct ScannerView: UIViewControllerRepresentable {
    let useCamera: Bool
    @Binding var image: UIImage?
    @Binding var detectedName: String
    @Binding var detectedDate: String
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = useCamera ? .camera : .photoLibrary
        return picker
    }

    // no-op
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    /// Handles image picking and text-recognition callbacks.
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parentView: ScannerView

        init(_ parent: ScannerView) {
            self.parentView = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            guard let uiImage = info[.originalImage] as? UIImage else {
                parentView.presentationMode.wrappedValue.dismiss()
                return
            }
            parentView.image = uiImage
            recognizeText(in: uiImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parentView.presentationMode.wrappedValue.dismiss()
        }

        private func recognizeText(in image: UIImage) {
            DispatchQueue.main.async {
                self.parentView.detectedName = "Scanning…"
                self.parentView.detectedDate = "Scanning…"
            }

            guard let cgImage = image.cgImage else {
                clearAndDismiss()
                return
            }

            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.clearAndDismiss()
                    return
                }

                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                let extractedDates = recognizedStrings.compactMap { $0.extractExpirationDate() }
                let extractedName = recognizedStrings.first(where: { $0.extractExpirationDate() == nil }) ?? ""

                DispatchQueue.main.async {
                    self.parentView.detectedName = extractedName
                    self.parentView.detectedDate = extractedDates.first ?? ""
                    self.parentView.presentationMode.wrappedValue.dismiss()
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.01

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    self.clearAndDismiss()
                }
            }
        }

        private func clearAndDismiss() {
            DispatchQueue.main.async {
                self.parentView.detectedName = ""
                self.parentView.detectedDate = ""
                self.parentView.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - String ExpirationDate Helper
/// Parses an expiration date string in MM/YY or MM-YYYY format and validates it is not in the past.
extension String {
    func extractExpirationDate() -> String? {
        let pattern = #"(0[1-9]|1[0-2])[/\-](\d{2}|\d{4})"#
        guard let range = self.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let found = String(self[range]).replacingOccurrences(of: "-", with: "/")
        let parts = found.split(separator: "/").map(String.init)
        guard parts.count == 2,
              let month = Int(parts[0]), (1...12).contains(month) else {
            return nil
        }

        let yearPart = parts[1]
        let year = yearPart.count == 4 ? String(yearPart.suffix(2)) : yearPart
        let now = Date(), cal = Calendar.current
        let currentMonth = cal.component(.month, from: now)
        let currentYear = cal.component(.year, from: now) % 100
        guard let yy = Int(year), yy > currentYear || (yy == currentYear && month >= currentMonth) else {
            return nil
        }

        return "\(parts[0])/\(year)"
    }
}
