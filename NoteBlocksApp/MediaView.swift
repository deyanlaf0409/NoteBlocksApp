//
//  MediaView.swift
//  NoteBlocks App
//
//  Created by Deyan on 25.02.25.
//


import SwiftUI
import PhotosUI
import UIKit

struct MediaPickerView: View {
    let noteID: UUID
    @Environment(\.presentationMode) var presentationMode
    @Binding var editedMedia: [String] // Assuming this stores file paths now
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 5) {
            // Image Preview Section
            if editedMedia.isEmpty {
                Image("upload") // Placeholder when no image exists
                    .resizable()
                    .scaledToFit()
                    .frame(width: 295, height: 295)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(0.9)
            } else {
                // Display images from editedMedia (file paths)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<editedMedia.count, id: \.self) { index in
                            // Load image from file path
                            if let uiImage = UIImage(contentsOfFile: editedMedia[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 295, height: 295)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.top, 0)
                                    .padding(.bottom, 0)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // First Row: Upload & Take Image
            HStack {
                Button(action: { showImagePicker = true }) {
                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                            .font(.system(size: 22))
                            .padding(.bottom, 0)
                        Text("Upload Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())

                Button(action: { showCamera = true }) {
                    VStack {
                        Image(systemName: "camera")
                            .foregroundColor(.orange)
                            .font(.system(size: 22))
                            .padding(.bottom, 0)
                        Text("Take Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())
            }
            .padding(.horizontal)
            .padding(.top, 0)
            .padding(.bottom, 2)

            // Second Row: Remove & Close
            HStack {
                Button(action: removeImage) {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                            .padding(.bottom, 0)
                        Text("Remove Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                            .padding(.bottom, 0)
                        Text("Close")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())
            }
            .padding(.horizontal)
            .padding(.top, 0)
            .padding(.bottom, 5)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(noteID: noteID, selectedImage: $selectedImage, editedMedia: $editedMedia)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, editedMedia: $editedMedia, noteID: noteID)
                .presentationDetents([.large, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func removeImage() {
        // First, check if the editedMedia array contains any data (which means an image is associated with this note)
        guard let filePath = editedMedia.first, !filePath.isEmpty else {
            // If no media is available, show a message
            print("No image associated with this note to remove.")
            return
        }
        
        // Now that we know there's an image, send the request to the server to remove the image
        let noteID = self.noteID // Note's UUID
        let urlString = "http://192.168.0.222/project/API/removeImage.php"
        
        // Send a POST request to the server (DELETE method might not be the best for this case)
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"  // Changed to POST for compatibility with the server
        
        // Prepare the body parameters for the server request
        let bodyParams = [
            "noteID": noteID.uuidString
        ]
        
        // Set up the HTTP body with the noteID
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParams, options: [])
        
        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received.")
                return
            }

            do {
                // Parse the response from the server
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["message"] as? String {
                    // Handle server response
                    print(message)

                    // If the response indicates success, remove the image from the app
                    if message.contains("deleted successfully") {
                        DispatchQueue.main.async {
                            // Remove the image from the editedMedia array and reset selected image
                            self.editedMedia.removeAll()
                            self.selectedImage = nil
                            // Optionally, show a success message in the UI
                            print("Image removed from app as well.")
                        }
                    }
                }

            } catch {
                print("Failed to parse response: \(error.localizedDescription)")
            }
        }.resume()
    }

    struct CustomButtonStyleMedia: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}



