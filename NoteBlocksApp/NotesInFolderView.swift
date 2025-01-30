//
//  NotesInFolderView.swift
//  NoteBlocks App
//
//  Created by Deyan on 28.01.25.
//

import SwiftUI

struct NotesInFolderView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var isEditing = false
    @State private var newFolderName = ""
    var folder: Folder

    var body: some View {
        VStack {
            HStack {
                // Folder name as Text or TextField depending on editing mode
                if isEditing {
                    TextField("New Folder Name", text: $newFolderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                } else {
                    Text(folder.name)
                        .font(.title)
                        .padding()
                }
                
                Spacer()
                
                // Edit Button (Pencil Icon)
                Button(action: {
                    toggleEditingMode()
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
            
            // Folder notes list
            List {
                ForEach(noteStore.notes.filter { $0.folderID == folder.id }) { note in
                    VStack(alignment: .leading) {
                        Text(note.text)
                            .font(.headline)
                        Text("Last Modified: \(note.dateModified.formatted())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("") // Empty title, we use the custom name in the top left
        .onAppear {
            // Initialize the folder's current name when the view appears
            newFolderName = folder.name
        }
    }

    // Function to toggle editing mode
    private func toggleEditingMode() {
        isEditing.toggle()
        
        if !isEditing {
            // Save the new name if editing is canceled
            if newFolderName != folder.name && !newFolderName.isEmpty {
                updateFolderName()
            } else {
                newFolderName = folder.name
            }
        }
    }

    // Function to handle the renaming of the folder
    private func updateFolderName() {
        // Call the update folder method to rename the folder
        noteStore.updateFolder(id: folder.id, newName: newFolderName)
        
        // Optionally, trigger a folder list refresh if necessary
        noteStore.loadFolders()
    }
}


