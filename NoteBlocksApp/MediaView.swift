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
    @Binding var note: Note
    let noteID: UUID
    @Environment(\.presentationMode) var presentationMode
    @Binding var editedMedia: [String] // Assuming this stores file paths now
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showFullScreenImage = false
    @State private var selectedFullScreenImage: UIImage?

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
                                    .onTapGesture {
                                                    selectedFullScreenImage = uiImage
                                                    showFullScreenImage = true
                                                }
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
                .onChange(of: selectedImage) { oldValue, newImage in
                    if let newImage = newImage {
                        // Save the image and update the editedMedia immediately
                        if let filePath = saveImage(image: newImage) {
                            DispatchQueue.main.async {
                                editedMedia = [filePath]
                                note.media = editedMedia
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, editedMedia: $editedMedia, noteID: noteID)
                .onChange(of: selectedImage) { oldValue, newImage in
                    if let newImage = newImage {
                        // Save the image and update the editedMedia immediately
                        if let filePath = saveImage(image: newImage) {
                            DispatchQueue.main.async {
                                editedMedia = [filePath]
                                note.media = editedMedia
                            }
                        }
                    }
                }
                .presentationDetents([.large, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let image = selectedFullScreenImage {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .background(Color.black)
                            .edgesIgnoringSafeArea(.all)
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }) {
                                Label("Save Image", systemImage: "square.and.arrow.down")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Close button in top-right corner
                    Button(action: {
                        showFullScreenImage = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                    }
                }
            }
        }


        




    }
    
    private func saveImage(image: UIImage) -> String? {
        guard let imageData = image.pngData() else { return nil }
        let fileName = noteID.uuidString + ".png"  // Use noteID as file name
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path  // Return file path as string
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    private func removeImage() {
        // First, check if the editedMedia array contains any data (which means an image is associated with this note)
        guard let filePath = editedMedia.first, !filePath.isEmpty else {
            print("No image associated with this note to remove.")
            return
        }

        // Check if the user is a guest
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        if userId.isEmpty {
            // Guest user: Remove image only from local storage
            do {
                try FileManager.default.removeItem(atPath: filePath)
                print("Image removed from local storage.")
            } catch {
                print("Error removing image from local storage: \(error.localizedDescription)")
            }

            // Remove the image from the app state
            DispatchQueue.main.async {
                self.editedMedia.removeAll()
                self.selectedImage = nil
                print("Image removed locally.")
            }
            return // Skip server removal for guest users
        }

        // If user is not a guest, proceed with the server request to remove the image
        let noteID = self.noteID.uuidString
        let urlString = "https://noteblocks.net/API/removeImage.php"

        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"

        let bodyParams = ["noteID": noteID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParams, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["message"] as? String {
                    print(message)

                    if message.contains("removed") {
                        DispatchQueue.main.async {
                            self.editedMedia.removeAll()
                            self.selectedImage = nil
                            self.note.media = []
                            self.editedMedia = []
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



