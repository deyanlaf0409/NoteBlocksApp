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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text(note.text)
                .font(.title)
                .padding()
            
            Text(note.body)
                .font(.body)
                .padding()
            
            if !note.media.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(note.media, id: \.self) { mediaPath in
                            if let uiImage = UIImage(contentsOfFile: mediaPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.top, 10)
                            }
                        }
                    }
                    .padding()
                }
            }

            
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
            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)
            
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
            .foregroundColor(.orange)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)
            
            Spacer()
        }
        .navigationTitle("Card Details")
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Archive")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.vertical, 3.5)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 150)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.black]),
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

        .padding()
        .blur(radius: (note.locked && !isAuthenticated) ? 10 : 0)
        .onAppear {
                if note.locked && !isAuthenticated {
                    authenticateUser { success in
                        if success {
                            isAuthenticated = true
                        } else {
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
            
            // Attempt to delete the associated image
            deleteImageForNote(noteId: note.id)
            
            // Save the changes
            noteStore.saveNotes()
            
            print("Note and associated image deleted locally.")

            // Go back to the previous screen
            presentationMode.wrappedValue.dismiss()
        } else {
            print("Note not found in archived notes.")
        }
    }

    // Function to delete an image based on the note's UUID
    private func deleteImageForNote(noteId: UUID) {
        let fileName = noteId.uuidString + ".png"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("Image deleted: \(fileURL.path)")
            } catch {
                print("Failed to delete image: \(error.localizedDescription)")
            }
        } else {
            print("No image found for note: \(noteId.uuidString)")
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

            // Check if user is a guest
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            if userId.isEmpty {
                print("Guest user: Note restored locally. No server sync required.")
                return
            }

            // Restore the note on the server first
            restoreNoteOnServer(restoredNote, userId: userId) { result in
                switch result {
                case .success:
                    print("Note restored successfully on the server.")

                    // After restoring, check for an existing image and upload if found
                    if let imagePath = getImagePathForNote(noteId: note.id),
                       let image = UIImage(contentsOfFile: imagePath) {
                        print("Image found for restored note. Uploading...")

                        uploadImage(image: image, noteID: note.id) { uploadResult in
                            switch uploadResult {
                            case .success:
                                print("Image successfully uploaded for restored note.")
                            case .failure(let error):
                                print("Failed to upload image: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("No image found for this note.")
                    }

                case .failure(let error):
                    print("Failed to restore note on the server: \(error.localizedDescription)")
                }
            }
        } else {
            print("Note not found in archived notes.")
        }
    }

    // Function to restore the note on the server
    private func restoreNoteOnServer(_ note: Note, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        noteStore.addNoteOnServer(note: note, userId: userId) { result in
            completion(result)
        }
    }

    // Function to get image path based on note UUID
    private func getImagePathForNote(noteId: UUID) -> String? {
        let fileName = noteId.uuidString + ".png"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL.path : nil
    }

    // Function to upload image
    private func uploadImage(image: UIImage, noteID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        if userId.isEmpty {
            print("Guest user: Image will not be uploaded.")
            completion(.success(()))  // Consider this as success since no upload is needed
            return
        }

        guard let imageData = image.pngData() else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])))
            return
        }

        guard let url = URL(string: "http://192.168.0.222/project/API/uploadImage.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
        // Note ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"noteID\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(noteID.uuidString)\r\n".data(using: .utf8)!)

        // Image Data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(noteID.uuidString).png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

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


