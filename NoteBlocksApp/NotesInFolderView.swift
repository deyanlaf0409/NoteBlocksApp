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
                    NavigationLink(destination: EditNoteView(note: $noteStore.notes[noteStore.notes.firstIndex(where: { $0.id == note.id })!])) {
                        VStack(alignment: .leading) {
                            Text(note.text)
                                .font(.headline)
                            Text("Last Modified: \(note.dateModified.formatted())")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
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




