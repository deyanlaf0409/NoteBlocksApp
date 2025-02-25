//
//  ImagePicker.swift
//  NoteBlocks App
//
//  Created by Deyan on 25.02.25.
//


import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var editedMedia: [Data]  // Storing file paths as Data

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self?.parent.selectedImage = uiImage
                        
                        // Save the image to the file system and get its file path
                        if let filePath = self?.saveImageToDocuments(image: uiImage) {
                            // Save file path as Data (UTF-8 encoded)
                            self?.parent.editedMedia = [filePath.data(using: .utf8)!]
                        }
                    }
                }
            }
        }

        // Function to save image to Documents directory
        private func saveImageToDocuments(image: UIImage) -> String? {
            // Choose PNG or JPEG based on your preference
            guard let imageData = image.pngData() else { return nil }  // Save as PNG
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


