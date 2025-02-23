//
//  ImagePicker.swift
//  NoteBlocks App
//
//  Created by Deyan on 22.02.25.
//
import SwiftUI

struct MediaPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var editedMedia: [Data]

    var body: some View {
        VStack(spacing: 20) {
            Text("Block Image")
                .font(.headline)
                .padding(.top)

            // Image Preview Section
            if !editedMedia.isEmpty, let uiImage = UIImage(data: editedMedia.first!) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            } else {
                Image("upload") // Ensure "placeholder" exists in Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 335, height: 335)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .opacity(0.9)
            }

            // First Row: Upload & Take Image
            HStack {
                Button(action: uploadImage) {
                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                            .font(.system(size: 24))
                        Text("Upload Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyle())

                Button(action: takePhoto) {
                    VStack {
                        Image(systemName: "camera")
                            .foregroundColor(.orange)
                            .font(.system(size: 24))
                        Text("Take Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyle())
            }
            .padding(.horizontal)

            // Second Row: Remove & Close
            HStack {
                Button(action: removeImage) {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                        Text("Remove Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyle())

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                        Text("Close")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyle())
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // Placeholder Functions
    private func uploadImage() {
        // Add logic to open photo library and select an image
    }

    private func takePhoto() {
        // Add logic to open camera and capture a photo
    }

    private func removeImage() {
        editedMedia.removeAll()
    }
    
}



