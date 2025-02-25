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
    @Environment(\.presentationMode) var presentationMode
    @Binding var editedMedia: [Data]
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 5) {
            Text("Block Image")
                .font(.headline)
                .padding(.top, 0)
                .padding(.bottom, 0)

            // Image Preview Section
            if let uiImage = selectedImage ?? (editedMedia.first.flatMap { UIImage(data: $0) }) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 295, height: 295)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 0)
                    .padding(.bottom, 0)
            } else {
                Image("upload") // Ensure placeholder exists in Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 295, height: 295)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 0)
                    .padding(.bottom, 0)
                    .opacity(0.9)
            }

            // First Row: Upload & Take Image
            HStack {
                Button(action: { showImagePicker = true }) {
                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                            .font(.system(size: 20))
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
                            .font(.system(size: 20))
                        Text("Take Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())
            }
            .padding(.horizontal)
            .padding(.top, 0)

            // Second Row: Remove & Close
            HStack {
                Button(action: removeImage) {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
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
                            .font(.system(size: 20))
                        Text("Close")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())
            }
            .padding(.horizontal)
            .padding(.bottom, 30)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, editedMedia: $editedMedia)
                .presentationDetents([.medium, .large]) // Allows resizing between medium and large
                .presentationDragIndicator(.visible) // Shows a drag indicator
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, editedMedia: $editedMedia)
                .presentationDetents([.large, .large])
                .presentationDragIndicator(.visible)
        }

    }

    private func removeImage() {
        editedMedia.removeAll()
        selectedImage = nil
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
