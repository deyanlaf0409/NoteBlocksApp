//
//  NotesInFolderView.swift
//  NoteBlocks App
//
//  Created by Deyan on 28.01.25.
//
import SwiftUI

struct NotesInFolderView: View {
    @EnvironmentObject var noteStore: NoteStore
    var folder: Folder

    var body: some View {
        List {
            // Filter notes by folderID to only show the ones assigned to this folder
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
        .navigationTitle(folder.name)
    }
}

