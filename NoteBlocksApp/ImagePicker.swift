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
    @Binding var editedMedia: [Data]

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
                        
                        // Save image as PNG to preserve transparency
                        if let imageData = uiImage.pngData() {
                            self?.parent.editedMedia = [imageData]
                        }
                    }
                }
            }

        }
    }
}
