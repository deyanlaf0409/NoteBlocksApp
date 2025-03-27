import SwiftUI

struct ArchiveView: View {
    @ObservedObject var noteStore: NoteStore // Observe changes in NoteStore
    @State private var showDeleteConfirmation = false // State for showing alert

    var body: some View {
        VStack {
            if noteStore.archivedNotes.isEmpty {
                VStack {
                    Image("archive") // Image should render here
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)
                        .opacity(0.9)

                            Text("Your archive is empty")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(noteStore.archivedNotes.reversed()) { note in
                        NavigationLink(destination: NoteDetailView(note: note, noteStore: noteStore)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(note.text)
                                        .font(.headline)
                                    Text("Archived: \(formattedDate(note.dateModified))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer() // Pushes the lock icon to the right
                                if note.locked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8) // Adjust spacing for better layout
                        }
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
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete") {
                deleteAllArchivedNotes()
            }
            .foregroundColor(.orange)
        } message: {
            Text("This action will delete all archived notes permanently.")
        }
    }

    // Function to delete all archived notes and their associated images
    private func deleteAllArchivedNotes() {
        for note in noteStore.archivedNotes {
            deleteImageForNote(noteId: note.id) // Delete associated image
        }
        
        noteStore.archivedNotes.removeAll() // Clear the archive
        noteStore.saveNotes() // Ensure persistence

        print("All archived notes and their images have been deleted.")
    }

    // Function to delete an image associated with a note
    private func deleteImageForNote(noteId: UUID) {
        let fileName = noteId.uuidString + ".png"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("Deleted image for note: \(noteId.uuidString)")
            } catch {
                print("Failed to delete image for note: \(noteId.uuidString). Error: \(error.localizedDescription)")
            }
        } else {
            print("No image found for note: \(noteId.uuidString)")
        }
    }


    // Format Date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

