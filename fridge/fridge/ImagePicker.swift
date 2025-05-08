//
//  ImagePicker.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI
import UIKit

struct FridgeImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        // Check if camera is available when camera source type is requested
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Fall back to photo library if camera isn't available
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = sourceType
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: FridgeImagePicker
        
        init(_ parent: FridgeImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Alert View for permissions
struct ImagePickerAlert: View {
    @Binding var isShowing: Bool
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .padding()
            
            Button("OK") {
                isShowing = false
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
} 