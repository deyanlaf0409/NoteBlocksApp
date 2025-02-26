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
    @State private var showFullScreenImage = false // New state variable

    var body: some View {
        VStack(spacing: 5) {
            // Image Preview Section
            if let uiImage = selectedImage ?? loadImageFromFile() {
                Button(action: { showFullScreenImage = true }) { // Tap to show full screen
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 295, height: 295)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 0)
                        .padding(.bottom, 0)
                }
                .buttonStyle(PlainButtonStyle()) // Ensures no button styling interference
            } else {
                Image("upload")
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
                            .font(.system(size: 25))
                            .padding(.bottom, 1)
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
                            .font(.system(size: 25))
                            .padding(.bottom, 1)
                        Text("Take Image")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(CustomButtonStyleMedia())
            }
            .padding(.horizontal)
            .padding(.top, 0)
            .padding(.bottom, 0)

            // Second Row: Remove & Close
            HStack {
                Button(action: removeImage) {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                            .font(.system(size: 25))
                            .padding(.bottom, 1)
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
                            .font(.system(size: 25))
                            .padding(.bottom, 1)
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
            ImagePicker(selectedImage: $selectedImage, editedMedia: $editedMedia)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, editedMedia: $editedMedia)
                .presentationDetents([.large, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(image: selectedImage ?? loadImageFromFile()!)
        }
    }

    private func loadImageFromFile() -> UIImage? {
        guard let filePath = editedMedia.first.flatMap({ String(data: $0, encoding: .utf8) }),
              let url = URL(string: filePath) else { return nil }
        return UIImage(contentsOfFile: url.path)
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
    
    // Full Screen Image View
    struct FullScreenImageView: View {
        let image: UIImage
        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
    }

}


