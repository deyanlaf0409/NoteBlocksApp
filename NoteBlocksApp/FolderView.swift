//
//  FolderView.swift
//  NoteBlocks App
//
//  Created by Deyan on 28.01.25.
//

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var newFolderName = ""
    @State private var folderListUpdated = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("New Folder Name", text: $newFolderName)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6))) // Light background
                    .padding(.horizontal, 8) // Keep consistent padding
                    .padding(.top, 15)


                Button(action: {
                    if !newFolderName.isEmpty {
                        noteStore.addFolder(name: newFolderName)
                        noteStore.saveFolders()
                        noteStore.loadFolders()
                        newFolderName = ""
                        folderListUpdated.toggle()  // Trigger a view update
                    }
                }) {
                    Text("+ 📁 Add Folder")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()

                List {
                    ForEach(noteStore.folders) { folder in
                        NavigationLink(destination: NotesInFolderView(folder: folder)) {
                            HStack {
                                Image(systemName: "folder.fill") // Use the folder icon
                                    .foregroundColor(.primary) // Adjust color as desired
                                Text(folder.name)
                                
                                
                                let noteCount = noteStore.notes.filter { $0.folderID == folder.id }.count
                                Text("\(noteCount)")
                                    .font(.body)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteFolder)
                }
            }
            
        }
        .navigationTitle("Manage Folders")
    }

    // Function to handle folder deletion
    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = noteStore.folders[index]  // Get the folder to be deleted
            noteStore.deleteFolder(folder)         // Pass the folder to deleteFolder method
        }
    }
}




