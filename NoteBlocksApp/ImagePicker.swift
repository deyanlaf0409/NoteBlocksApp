//
//  ImagePicker.swift
//  NoteBlocks App
//
//  Created by Deyan on 25.02.25.
//


import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    let noteID: UUID
    @Binding var selectedImage: UIImage?
    @Binding var editedMedia: [String]  // Storing file paths as Strings (not Data)

    func makeCoordinator() -> Coordinator {
        Coordinator(self, noteID: noteID)
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
        let noteID: UUID

        init(_ parent: ImagePicker, noteID: UUID) {
            self.parent = parent
            self.noteID = noteID
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self?.parent.selectedImage = uiImage
                        
                        // Save the image to the file system with the noteID as the file name
                        if let filePath = self?.saveImageToDocuments(image: uiImage) {
                            // Save file path as String
                            self?.parent.editedMedia = [filePath]

                            // Check if user is a guest using UserDefaults before uploading
                            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
                            if userId.isEmpty {
                                print("Guest user: Image will not be uploaded.")
                            } else {
                                // If user is not a guest, proceed with image upload
                                self?.uploadImage(image: uiImage, noteID: self?.noteID ?? UUID())
                            }
                        }
                    }
                }
            }
        }

        // Function to save image to Documents directory and return file path as string
        private func saveImageToDocuments(image: UIImage) -> String? {
            // Use the noteID as the image file name
            guard let imageData = image.pngData() else { return nil }  // Save as PNG
            let fileName = noteID.uuidString + ".png"  // Use noteID as the file name with .png extension
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                return fileURL.path  // Return the file path as string
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }

        // Function to upload image
        private func uploadImage(image: UIImage, noteID: UUID) {
            // Convert UIImage to PNG Data
            guard let imageData = image.pngData() else {
                print("Failed to convert image to PNG data")
                return
            }

            // URLRequest setup for image upload
            guard let url = URL(string: "https://noteblocks.net/API/uploadImage.php") else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            
            // Add Note ID as a form field
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"noteID\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(noteID.uuidString)\r\n".data(using: .utf8)!)  // Attach noteID
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(noteID.uuidString).png\"\r\n".data(using: .utf8)!)  // Use noteID for filename
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            let task = URLSession.shared.dataTask(with: request) { data, response, error in

                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }

                if let response = response as? HTTPURLResponse {
                    // Check HTTP status code
                    print("HTTP Status Code: \(response.statusCode)")
                }

                if let data = data {
                    // Print raw response data for debugging
                    if let rawResponse = String(data: data, encoding: .utf8) {
                        print("Raw response: \(rawResponse)")
                    }

                    do {
                        // Parse the response from the server
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let fileUrl = jsonResponse["fileUrl"] as? String {
                            print("Image uploaded successfully: \(fileUrl)")
                        } else {
                            print("Failed to get image URL from server")
                        }
                    } catch {
                        print("Failed to parse response: \(error.localizedDescription)")
                    }
                } else {
                    print("No response from server")
                }
            }

            task.resume()
        }
    }
}





