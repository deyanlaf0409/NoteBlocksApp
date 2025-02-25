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

            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                    parent.editedMedia = [imageData]
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
