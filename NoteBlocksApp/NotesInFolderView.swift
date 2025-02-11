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
            HStack {
                // Always show TextField for editing folder name
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
                
                Spacer()
            }
            .padding(10)
            
            // Folder notes list
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
        }
        .navigationTitle("") // Empty title, we use the custom name in the top left
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

