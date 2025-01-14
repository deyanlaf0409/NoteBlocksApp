//
//  NoteStore.swift
//  Late-Night Notes
//
//  Created by Deyan on 5.10.24.
//

import Foundation
import SwiftUI

class NoteStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }
    
    @Published var archivedNotes: [Note] = [] {
        didSet{
            saveArchivedNotes()
        }
    }
    
    private let notesKey = "savedNotes"
    private let archivedNotesKey = "archivedNotes"

    
    init() {
        loadNotes()
        loadArchivedNotes()
    }
    
    
    func addNote(_ text: String) {
        let newNote = Note(text: text)
        notes.append(newNote)
        sortNotes()
        saveNotes()
        print("Added guest note: \(newNote.text)")
    
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            if userId.isEmpty {
                print("Guest user: Note created locally.")
            } else {
                
                // Call API
                addNoteOnServer(note: newNote, userId: userId) { result in
                    switch result {
                    case .success:
                        print("Note created successfully on server.")
                    case .failure(let error):
                        print("Failed to create note on server: \(error.localizedDescription)")
                    }
                }
            }
        }
    
    
    func updateNoteText(_ note: Binding<Note>, with newText: String) {
        note.wrappedValue.text = newText
        note.wrappedValue.dateModified = Date()
        
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        if userId.isEmpty {
            print("Guest user: Note updated locally.")
        } else {
            
            // Call API
            updateNoteOnServer(note: note.wrappedValue) { result in
                switch result {
                case .success:
                    // Note updated successfully on server
                    print("Note updated successfully on server.")
                case .failure(let error):
                    // Handle error appropriately
                    print("Failed to update note on server: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    private func cancelNotification(for note: inout Note) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [note.id.uuidString])
        note.reminderDate = nil
        print("Notification cancelled for archived note.")
    }


    
    func deleteNote(at offsets: IndexSet) {
        // Get the note IDs for deletion
        let noteIdsToDelete = offsets.map { notes[$0].id }

        // Remove notes locally
        //notes.remove(atOffsets: offsets)
        for offset in offsets {
                // Set the isArchived property to true for the note at the current offset
                notes[offset].isArchived = true
                notes[offset].dateModified = Date()
                var note = notes[offset]
            cancelNotification(for: &note)
                archivedNotes.append(note)
            }
        notes.remove(atOffsets: offsets)
        
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        if userId.isEmpty {
            print("Guest user: Note archived locally.")
        } else {
            
            for noteId in noteIdsToDelete {
                deleteNoteOnServer(noteId: noteId) { result in
                    switch result {
                    case .success:
                        print("Note deleted successfully on server.")
                    case .failure(let error):
                        print("Failed to delete note on server: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    
    func toggleHighlight(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].highlighted.toggle()
            let updatedNote = notes[index]
            
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            
            if userId.isEmpty {
                print("Guest user: Highlight toggled locally.")
            } else {
                
                updateNoteOnServer(note: updatedNote) { result in
                    switch result {
                    case .success:
                        print("Highlight status updated on server.")
                    case .failure(let error):
                        // Rollback if server update fails
                        DispatchQueue.main.async {
                            self.notes[index].highlighted.toggle() // Undo toggle
                            print("Failed to update highlight on server: \(error.localizedDescription)")
                        }
                    }
                }
            }
            sortNotes()
            saveNotes()
        }
    }




    public func sortNotes() {
        notes.sort {
            if $0.highlighted != $1.highlighted {
                return $0.highlighted && !$1.highlighted //Highlighted first
            } else {
                return $0.dateModified > $1.dateModified
            }
        }
    }

    
    public func saveNotes() {
        if let encodedNotes = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encodedNotes, forKey: notesKey)
        }
    }
    
    
    public func saveArchivedNotes() {
            if let encodedArchivedNotes = try? JSONEncoder().encode(archivedNotes) {
                UserDefaults.standard.set(encodedArchivedNotes, forKey: archivedNotesKey)
            }
        }
    
    
    public func loadNotes() {
        
        if let savedNotesData = UserDefaults.standard.data(forKey: notesKey) {
            if let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotesData) {
                self.notes = decodedNotes
                sortNotes()
            }
        }
    }
    
    private func loadArchivedNotes() {
            if let savedArchivedNotesData = UserDefaults.standard.data(forKey: archivedNotesKey),
               let decodedArchivedNotes = try? JSONDecoder().decode([Note].self, from: savedArchivedNotesData) {
                self.archivedNotes = decodedArchivedNotes
            }
        }
    
    
    //MARK: - Server Add Method
    
    public func addNoteOnServer(note: Note, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.222/project/API/addNote.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" // Format for PostgreSQL
        let formattedDateCreated = dateFormatter.string(from: note.dateCreated) // Use dateCreated here
        let formattedDateModified = dateFormatter.string(from: note.dateModified) // Use dateModified here

        let json: [String: Any] = [
            "note_id": note.id.uuidString,
            "user_id": userId,               // Include userId
            "text": note.text,               // Note text
            "dateCreated": formattedDateCreated, // Include created date
            "dateModified": formattedDateModified // Include modified date
        ]

        // Print the JSON for debugging
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) // Convert to String for logging
            print("Sending JSON: \(jsonString ?? "nil")") // Print the JSON
            request.httpBody = jsonData // Set the request body to the serialized JSON
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Check response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            
            completion(.success(()))
        }

        task.resume()
    }

    
    // MARK: - Server Update Method
    
    private func updateNoteOnServer(note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.222/project/API/updateNote.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" //database format
        let formattedDate = dateFormatter.string(from: note.dateModified)

        let json: [String: Any] = [
            "id": note.id.uuidString,
            "text": note.text,
            "dateModified": formattedDate,
            "highlight": note.highlighted
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("Sending JSON for update: \(jsonString ?? "nil")")
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            completion(.success(()))
        }

        task.resume()
    }
    
    // MARK: - Server Delete Method
    
    private func deleteNoteOnServer(noteId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.222/project/API/deleteNote.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "note_id": noteId.uuidString
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("Sending JSON for delete: \(jsonString ?? "nil")")
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            completion(.success(()))
        }

        task.resume()
    }
}
