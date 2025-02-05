//
//  ArchiveDetail.swift
//  Late-Night Notes
//
//  Created by Deyan on 30.11.24.
//

import SwiftUI
import LocalAuthentication

struct NoteDetailView: View {
    var note: Note
    @ObservedObject var noteStore: NoteStore
    @Environment(\.presentationMode) var presentationMode // This is the key for navigating back
    @State private var isAuthenticated: Bool = false

    var body: some View {
        VStack {
            Text(note.text)
                .font(.title)
                .padding()
            
            Text("Created: \(formattedDate(note.dateCreated))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 10)
            
            Button("Restore") {
                restoreNote(note)
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: 150)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.black]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            
            // Delete Button
            Button("Delete") {
                deletedNote(note)
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: 150)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.black]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            
            Spacer()
        }
        .navigationTitle("Note Details")
        .padding()
        .onAppear {
            // Check if the note is locked and ask for authentication
            if note.locked && !isAuthenticated {
                authenticateUser { success in
                    if success {
                        isAuthenticated = true
                    } else {
                        // If authentication failed or was canceled, dismiss the view
                        print("Authentication failed or canceled!")
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Local delete note functionality
    private func deletedNote(_ note: Note) {
        // Remove the note from the archived notes list
        if let index = noteStore.archivedNotes.firstIndex(where: { $0.id == note.id }) {
            noteStore.archivedNotes.remove(at: index)
            
            // Save the changes
            noteStore.saveNotes()
            
            print("Note deleted locally.")
            
            // Go back to the previous screen
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func restoreNote(_ note: Note) {
        // Remove the note from the archived notes list
        if let index = noteStore.archivedNotes.firstIndex(where: { $0.id == note.id }) {
            noteStore.archivedNotes.remove(at: index)
            
            // Update the note's state and add it back to the active notes list
            var restoredNote = note
            restoredNote.isArchived = false
            
            noteStore.notes.append(restoredNote)
            
            // Save the changes locally
            noteStore.sortNotes()
            
            print("Note restored locally.")
            
            presentationMode.wrappedValue.dismiss()
            
            // Sync with the server if the user is logged in
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            if userId.isEmpty {
                print("Guest user: Note restored locally.")
            } else {
                // Sync the restored note with the server
                noteStore.addNoteOnServer(note: restoredNote, userId: userId) { result in
                    switch result {
                    case .success:
                        print("Note restored successfully on the server.")
                    case .failure(let error):
                        print("Failed to restore note on the server: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("Note not found in archived notes.")
        }
    }
}

private func authenticateUser(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Please authenticate to access this note") { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    completion(false)
                    print(authenticationError?.localizedDescription ?? "Authentication failed")
                }
            }
        }
    } else {
        completion(false)
        print(error?.localizedDescription ?? "Biometrics not available")
    }
}


