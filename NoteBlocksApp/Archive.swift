//
//  Archive.swift
//  Late-Night Notes
//
//  Created by Deyan on 30.11.24.
//

import SwiftUI

struct ArchiveView: View {
    @ObservedObject var noteStore: NoteStore // Observe changes in NoteStore

    var body: some View {
        List {
            ForEach(noteStore.archivedNotes.reversed()) { note in
                // Wrap each note with a NavigationLink
                NavigationLink(destination: NoteDetailView(note: note, noteStore: noteStore)) {
                    VStack(alignment: .leading) {
                        Text(note.text)
                            .font(.headline)
                        Text("Archived: \(formattedDate(note.dateModified))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Archived Notes")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

