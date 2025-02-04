import SwiftUI

struct ArchiveView: View {
    @ObservedObject var noteStore: NoteStore // Observe changes in NoteStore
    @State private var showDeleteConfirmation = false // State for showing alert

    var body: some View {
        List {
            ForEach(noteStore.archivedNotes.reversed()) { note in
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
        .toolbar {
            if !noteStore.archivedNotes.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDeleteConfirmation = true // Show confirmation alert
                    }) {
                        Text("Delete All")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllArchivedNotes()
            }
        } message: {
            Text("This action will delete all archived notes permanently.")
        }
    }

    // Function to delete all archived notes
    private func deleteAllArchivedNotes() {
        noteStore.archivedNotes.removeAll() // Clear the archive
        noteStore.saveNotes() // Ensure persistence if needed
    }

    // Format Date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

