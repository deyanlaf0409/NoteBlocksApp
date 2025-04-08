//
//  NotesInFolderView.swift
//  NoteBlocks App
//
//  Created by Deyan on 28.01.25.
//

import SwiftUI

struct NotesInFolderView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var newFolderName = ""
    @State private var loggedInUser: String? = UserDefaults.standard.string(forKey: "loggedInUser")
    @State private var showFullScreenImage = false
    @State private var selectedImage: UIImage? = nil
    var folder: Folder

    var body: some View {
        VStack {
            ZStack {
                // Folder image that stays at the top
                Image("folderIN") // Replace with your image name
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width, height: 200) // Make image span the width
                    .clipped() // Ensure it doesn't overflow
                    .opacity(0.9)
                    .padding(.top, -80) // Move the image up slightly without overlapping
                
                VStack {
                    // Folder name input field
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                        
                        TextField("Folder Name", text: $newFolderName, onCommit: {
                            updateFolderName()
                        })
                        .foregroundColor(.primary)
                        .padding(5)
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                    .padding(.horizontal, 10)
                    .padding(.top, 160) // Adjust to ensure the text field appears below the image
                }
            }
            
            // Notes list
            List {
                ForEach(noteStore.notes.filter { $0.folderID == folder.id }) { note in
                    NavigationLink(destination: EditNoteView(note: $noteStore.notes[noteStore.notes.firstIndex(where: { $0.id == note.id })!], username: loggedInUser ?? "Guest")) {
                        VStack(alignment: .leading) {
                            HStack {
                                // Show image if note has media
                                if let firstImagePath = note.media.first, let uiImage = UIImage(contentsOfFile: firstImagePath) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 65, height: 65)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .blur(radius: note.locked ? 10 : 0)
                                        .padding(.trailing, 8)
                                        .onTapGesture {
                                            if !note.locked {
                                                selectedImage = uiImage
                                                // Trigger full screen display only after setting the image
                                                DispatchQueue.main.async {
                                                    showFullScreenImage = true
                                                }
                                            }
                                        }
                                }

                                // Text part of the note
                                VStack(alignment: .leading) {
                                    Text(note.text)
                                        .font(.headline)
                                    
                                    Text("Last Modified: \(note.dateModified.formatted())")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            if note.locked {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }

            .padding(.top, 20) // Add space between the folder name and the notes list
        }
        .navigationTitle("") // Empty title, custom name is used in the navigation bar
        .onAppear {
            newFolderName = folder.name
        }
        .onChange(of: selectedImage) { oldValue, _ in
            // Whenever the selectedImage changes, trigger a view update
            showFullScreenImage = false // Reset to false before showing
        }
        .fullScreenCover(isPresented: $showFullScreenImage, content: {
            if let image = selectedImage {
                FullScreenImage(showFullScreenImage: $showFullScreenImage, image: image)
            } else {
                Text("No image available")
                    .foregroundColor(.white)
            }
        })
    }

    // Function to update the folder name when TextField editing is finished
    private func updateFolderName() {
        guard !newFolderName.isEmpty, newFolderName != folder.name else {
            newFolderName = folder.name // Reset if empty or unchanged
            return
        }
        noteStore.updateFolder(id: folder.id, newName: newFolderName)
        noteStore.loadFolders() // Refresh folder list if necessary
    }
}






