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
    
    @Published var folders: [Folder] = [] {
            didSet {
                saveFolders()
            }
        }
        
    
    private let notesKey = "savedNotes"
    private let archivedNotesKey = "archivedNotes"
    private let foldersKey = "savedFolders"

    
    init() {
        loadNotes()
        loadArchivedNotes()
        loadFolders()
    }
    
    
    func addFolder(name: String) {
        let newFolder = Folder(id: UUID(), name: name)
        folders.append(newFolder)
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        if userId.isEmpty {
            print("Guest user: Folder created locally.")
        }else{
            addFolderToServer(folder: newFolder, userId: userId)
        }
        
        // Save updated folders to UserDefaults
        saveFolders()
    }
    
    
    
    func updateFolder(id: UUID, newName: String) {
        // Find the folder locally by its id
        if let folderIndex = folders.firstIndex(where: { $0.id == id }) {
            // Update the folder's name locally
            folders[folderIndex].name = newName
            
            // Get the userId from UserDefaults
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            
            // If the user is logged in, update the folder on the server
            if !userId.isEmpty {
                updateFolderOnServer(folderId: id, newName: newName, userId: userId)
            } else {
                print("Guest user: Folder updated locally.")
            }
            
            // Save the updated folders to UserDefaults
            saveFolders()
        } else {
            print("Folder not found.")
        }
    }
    
    
    
    func deleteFolder(_ folder: Folder) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        // Find notes in the folder
        let notesToArchive = notes.filter { $0.folderID == folder.id }
        
        // Archive notes locally
        for note in notesToArchive {
            var archivedNote = note
            archivedNote.isArchived = true
            archivedNote.folderID = nil
            archivedNote.dateModified = Date()
            cancelNotification(for: &archivedNote)
            archivedNotes.append(archivedNote)
            
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes.remove(at: index)
            }
        }
        
        // Remove the folder locally
        if let folderIndex = folders.firstIndex(where: { $0.id == folder.id }) {
            folders.remove(at: folderIndex) // Remove the folder from the local array
        }

        // Save locally
        saveFolders()
        saveNotes()
        saveArchivedNotes()

        // If it's a guest user, just print locally
        if userId.isEmpty {
            print("Guest user: Folder deleted locally.")
        } else {
            // 3. Delete notes first
            deleteNotesInFolder(notes: notesToArchive, folderId: folder.id, userId: userId) {
                // After deleting all notes, delete the folder from the server
                self.deleteFolderFromServer(folderId: folder.id, userId: userId)
            }
        }
    }


    
    
    
    func deleteNotesInFolder(notes: [Note], folderId: UUID, userId: String, completion: @escaping () -> Void) {
        var remainingNotes = notes

        guard !remainingNotes.isEmpty else {
            // No more notes to delete, trigger the folder deletion
            completion()
            return
        }

        let noteToDelete = remainingNotes.removeFirst()

        deleteNoteOnServer(noteId: noteToDelete.id) { result in
            switch result {
            case .success:
                print("Note deleted successfully on server.")
            case .failure(let error):
                print("Failed to delete note on server: \(error.localizedDescription)")
            }
            // Recursively delete the next note
            self.deleteNotesInFolder(notes: remainingNotes, folderId: folderId, userId: userId, completion: completion)
        }
    }








        
        func folderName(for id: UUID?) -> String? {
            return folders.first(where: { $0.id == id })?.name
        }
    
    func saveFolders() {
            if let encoded = try? JSONEncoder().encode(folders) {
                UserDefaults.standard.set(encoded, forKey: foldersKey)
            }
        }
        
    func loadFolders() {
        if let savedData = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([Folder].self, from: savedData) {
            folders = decoded
            print("Loaded folders: \(folders)")  // Debugging line
        }
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
                        //DispatchQueue.main.async {
                           //self.notes[index].highlighted.toggle()
                            print("Failed to update highlight on server: \(error.localizedDescription)")
                        //}
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
    
    func clearNotes() {
            notes.removeAll()
            print("Cleared all notes from NoteStore")
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
    
    
    private func uploadImage(image: UIImage, noteID: UUID) {
        // Convert UIImage to PNG Data
        guard let imageData = image.pngData() else {
            print("Failed to convert image to PNG data")
            return
        }

        // URLRequest setup for image upload
        guard let url = URL(string: "http://192.168.0.222/project/API/uploadImage.php") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
        // Add Note ID as a form field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"noteID\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(noteID.uuidString)\r\n".data(using: .utf8)!)  // Attach noteID
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(noteID.uuidString).png\"\r\n".data(using: .utf8)!)  // Use noteID for filename
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                // Check HTTP status code
                print("HTTP Status Code: \(response.statusCode)")
            }

            if let data = data {
                // Print raw response data for debugging
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawResponse)")
                }

                do {
                    // Parse the response from the server
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let fileUrl = jsonResponse["fileUrl"] as? String {
                        print("Image uploaded successfully: \(fileUrl)")
                    } else {
                        print("Failed to get image URL from server")
                    }
                } catch {
                    print("Failed to parse response: \(error.localizedDescription)")
                }
            } else {
                print("No response from server")
            }
        }

        task.resume()
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
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let formattedDateCreated = dateFormatter.string(from: note.dateCreated)
        let formattedDateModified = dateFormatter.string(from: note.dateModified)

        let json: [String: Any] = [
            "note_id": note.id.uuidString,
            "user_id": userId,
            "text": note.text,
            "body": note.body,
            "dateCreated": formattedDateCreated,
            "dateModified": formattedDateModified,
            "folderId": note.folderID?.uuidString ?? "",
            "media": note.media // This is now an array
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            print("Sending JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
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

            // If media is not empty, attempt to upload images
            // Check if note.media exists and is not empty
            if !note.media.isEmpty {
                for mediaPath in note.media {
                    if let image = UIImage(contentsOfFile: mediaPath) {
                        self.uploadImage(image: image, noteID: note.id)
                    } else {
                        print("Invalid image file at path: \(mediaPath)")
                    }
                }
            }


            completion(.success(()))
        }

        task.resume()
    }



    
    // MARK: - Server Update Method
    
    public func updateNoteOnServer(note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
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
            "body": note.body,
            "dateModified": formattedDate,
            "highlight": note.highlighted,
            "folderId": note.folderID?.uuidString ?? "",
            "locked": note.locked
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
        removeImageFromServer(noteId: noteId) { result in
            switch result {
            case .success:
                print("Image(s) removed successfully or no media found. Proceeding to delete note.")
                self.performNoteDeletion(noteId: noteId, completion: completion)

            case .failure(let error):
                let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""

                // If the error message is "No media found for this note", proceed with note deletion
                if errorMessage.contains("No media found for this note") {
                    print("No media found, but continuing to delete the note.")
                    self.performNoteDeletion(noteId: noteId, completion: completion)
                } else {
                    print("Failed to remove image: \(errorMessage)")
                    completion(.failure(error)) // Stop deletion for other errors
                }
            }
        }
    }


    // Function to remove the image before deleting the note
    private func removeImageFromServer(noteId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.222/project/API/removeImage.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "noteID": noteId.uuidString
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
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

    // Function to delete the note after images are removed
    private func performNoteDeletion(noteId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
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

    
    
    // MARK: - Server Add Folder Method
    // Modified to upload the existing folder id
        public func addFolderToServer(folder: Folder, userId: String) {
            guard let url = URL(string: "http://192.168.0.222/project/API/addFolder.php") else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Use the existing id of the folder
            let json: [String: Any] = [
                "folder_id": folder.id.uuidString, // Use the existing UUID
                "user_id": userId,
                "name": folder.name
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8) // Convert to String for logging
                print("Sending JSON: \(jsonString ?? "nil")") // Print the JSON
                request.httpBody = jsonData // Set the request body to the serialized JSON
            } catch {
                print("Error serializing JSON: \(error)")
                return
            }

            // Perform the network request to add the folder on the server
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending request: \(error)")
                    return
                }

                // Check response status
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    print("Error: Invalid server response")
                    return
                }

            }

            task.resume() // Start the network request
        }
    
    
    
    
    // MARK: - Server Delete Folder Method
    public func deleteFolderFromServer(folderId: UUID, userId: String) {
        let url = URL(string: "http://192.168.0.222/project/API/deleteFolder.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print(folderId.uuidString)

        let requestBody: [String: Any] = ["folderId": folderId.uuidString, "userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to delete folder: \(error.localizedDescription)")
                return
            }

            // Check HTTP Response Status Code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Folder deleted successfully from server")
                } else {
                    print("Failed to delete folder, HTTP Status Code: \(httpResponse.statusCode)")
                }
            }

            // Check response data (JSON)
            if let data = data {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let message = responseJSON?["message"] as? String {
                        print("Server response message: \(message)")
                    }
                } catch {
                    print("Failed to parse JSON response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    
    
    
    //MARK: - update the folder on the server
    public func updateFolderOnServer(folderId: UUID, newName: String, userId: String) {
        guard let url = URL(string: "http://192.168.0.222/project/API/updateFolder.php") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare the JSON body to update the folder
        let json: [String: Any] = [
            "folderId": folderId.uuidString, // Folder ID
            "userId": userId,                // User ID
            "name": newName                   // New name for the folder
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) // Convert to String for logging
            print("Sending JSON: \(jsonString ?? "nil")") // Print the JSON
            request.httpBody = jsonData // Set the request body to the serialized JSON
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        // Perform the network request to update the folder on the server
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request: \(error)")
                return
            }

            // Check response status
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error: Invalid server response")
                return
            }

            // Optionally, parse the server response if needed
            if let data = data {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let message = responseJSON?["message"] as? String {
                        print("Server response message: \(message)")
                    }
                } catch {
                    print("Failed to parse JSON response: \(error.localizedDescription)")
                }
            }
        }

        task.resume() // Start the network request
    }



}
