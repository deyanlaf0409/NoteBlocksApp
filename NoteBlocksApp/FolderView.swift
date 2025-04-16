//
//  FolderView.swift
//  NoteBlocks App
//
//  Created by Deyan on 28.01.25.
//

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var noteStore: NoteStore
    @Environment(\.dismiss) private var dismiss
    @State private var newFolderName = ""
    @State private var folderListUpdated = false

    var body: some View {
        NavigationView {
    
            VStack {
                // Test Image Directly:
                if let _ = UIImage(named: "folders") {
                    Image("folders") // Image should render here
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .opacity(0.9)
                        .padding(.top, 1)
                } else {
                    Text("Image not found")
                        .foregroundColor(.red)
                        .padding()
                }
                HStack {
                        // TextField
                        TextField("New Folder Name", text: $newFolderName)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                            .padding(.horizontal, 5)
                            .frame(width: 200) // Adjust width to your preference
                            .padding(.top, 1)
                        
                    Button(action: {
                        if !newFolderName.isEmpty {
                            noteStore.addFolder(name: newFolderName)
                            noteStore.saveFolders()
                            noteStore.loadFolders()
                            newFolderName = ""
                            folderListUpdated.toggle()
                        }
                    }) {
                        Text("+ 📁 Add Folder")
                            .font(.system(size: 18, weight: .bold, design: .rounded)) // Smaller font size
                            .padding(10) // Reduced padding
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)
                    }

                        .padding(.top, 1) // Adjust the padding to align with the text field
                    }
                    .padding(.horizontal, 10) // To make sure the HStack has proper padding


                List {
                    if noteStore.folders.isEmpty {
                        Text("No folders yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(noteStore.folders) { folder in
                            NavigationLink(destination: NotesInFolderView(folder: folder)) {
                                HStack {
                                    Image("folder") // Replace with your actual image asset name
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 27, height: 27) // Match system image size
                                            .foregroundColor(.primary)
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
                .background(Color.clear)
            }
        }
        .navigationTitle("Manage Folders")
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.vertical, 3.5)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 150)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primary, Color.primary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.gray)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)
                }
            }
        }

    }

    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = noteStore.folders[index]
            noteStore.deleteFolder(folder)
        }
    }
}





