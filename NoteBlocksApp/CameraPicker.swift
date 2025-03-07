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
    @Binding var editedMedia: [String]  // Store file paths as Strings instead of Data
    var noteID: UUID  // Add noteID parameter

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
                    parent.editedMedia = [filePath]  // Save file path as String

                    // Check if user is a guest using UserDefaults before uploading
                    let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
                    if userId.isEmpty {
                        print("Guest user: Image will be saved locally.")
                        // Only save the image locally for guest users
                    } else {
                        // If user is not a guest, proceed with image upload
                        self.uploadImage(image: uiImage, noteID: parent.noteID)
                    }
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // Function to save image to Documents directory and return file path as string
        private func saveImageToDocuments(image: UIImage) -> String? {
            guard let imageData = image.pngData() else { return nil }
            let fileName = parent.noteID.uuidString + ".png"  // Use noteID as file name
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                return fileURL.path  // Return file path as string
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
            guard let url = URL(string: "http://192.168.0.222/project/API/uploadImage.php") else {
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
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
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




