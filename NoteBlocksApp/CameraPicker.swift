//
//  CameraPicker.swift
//  NoteBlocks App
//
//  Created by Deyan on 25.02.25.
//


import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var editedMedia: [Data]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)

            // Check if edited or original image is available
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage

                // Save image to file system and get file path
                if let filePath = self.saveImageToDocuments(image: uiImage) {
                    // Store the file path as Data
                    parent.editedMedia = [filePath.data(using: .utf8)!] // Save file path as Data
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // Function to save image to Documents directory
        private func saveImageToDocuments(image: UIImage) -> String? {
            // Choose PNG or JPEG based on your preference
            guard let imageData = image.pngData() else { return nil } // Save as PNG
            let fileName = UUID().uuidString + ".png"  // Generate unique file name with .png extension
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                return fileURL.path  // Return file path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
    }
}

