
import SwiftUI
import Network
import UserNotifications

@main
struct Late_Night_NotesApp: App {
    @State private var loggedInUser: String? = UserDefaults.standard.string(forKey: "loggedInUser")
    @State private var showNotes: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var showSafari = false
    @StateObject private var noteStore = NoteStore()
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var localNetworkPermissionRequested = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            if showNotes {
                ContentView(username: loggedInUser ?? "Guest", onLogout: resetToInitialState)
                    .environmentObject(noteStore)
                    .environmentObject(networkMonitor)
                    .onOpenURL { url in
                        handleDeepLink(url: url)
                    }
                    .onAppear {
                        fetchUserData()
                        startPeriodicFetch()
                    }
            } else {
                IntroView(
                    loggedInUser: $loggedInUser,
                    showNotes: $showNotes,
                    showSafari: $showSafari
                )
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .environmentObject(noteStore)
            }
        }
    }
    
    
    private func startPeriodicFetch() {
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in  // Every 5 minutes
                fetchUserData()
            }
        }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "latenightnotes", let host = url.host else {
            print("Invalid deep link")
            return
        }

        if host == "auth", let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            if let status = queryItems.first(where: { $0.name == "status" })?.value,
               status == "success",
               let username = queryItems.first(where: { $0.name == "username" })?.value,
               let userIdString = queryItems.first(where: { $0.name == "user_id" })?.value,
               let userId = Int(userIdString),
               let notesString = queryItems.first(where: { $0.name == "notes" })?.value,
               let foldersString = queryItems.first(where: { $0.name == "folders" })?.value {

                noteStore.loadNotes()
                print("Loaded guest notes: \(noteStore.notes.map { $0.text })")

                if let decodedNotesData = Data(base64Encoded: notesString),
                   let decodedFoldersData = Data(base64Encoded: foldersString) {
                    let decoder = JSONDecoder()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSS"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)

                    do {
                        let rawNotes = try JSONSerialization.jsonObject(with: decodedNotesData) as? [[String: Any]]
                        let rawFolders = try JSONSerialization.jsonObject(with: decodedFoldersData) as? [[String: Any]]

                        var fetchedNotes: [Note] = []
                        let fetchedFolders = rawFolders?.compactMap { rawFolder -> Folder? in
                            guard let idString = rawFolder["id"] as? String,
                                  let name = rawFolder["name"] as? String else {
                                return nil
                            }
                            return Folder(id: UUID(uuidString: idString) ?? UUID(), name: name)
                        } ?? []

                        let downloadGroup = DispatchGroup()

                        rawNotes?.forEach { rawNote in
                            guard let idString = rawNote["id"] as? String,
                                  let text = rawNote["text"] as? String,
                                  let body = rawNote["body"] as? String,
                                  let dateCreatedString = rawNote["dateCreated"] as? String,
                                  let dateModifiedString = rawNote["dateModified"] as? String,
                                  let highlightedString = rawNote["highlighted"] as? String,
                                  let lockedString = rawNote["locked"] as? String else {
                                return
                            }

                            let dateCreated = dateFormatter.date(from: dateCreatedString) ?? Date()
                            let dateModified = dateFormatter.date(from: dateModifiedString) ?? Date()
                            let highlighted = (highlightedString == "t")
                            let locked = (lockedString == "t")
                            let folderId: UUID? = (rawNote["folderId"] as? String).flatMap(UUID.init)
                            
                            // Initialize an empty media array for the note (ensure only one image is associated)
                            let mediaData: [String] = []

                            // Create the note
                            var note = Note(id: UUID(uuidString: idString) ?? UUID(),
                                            text: text,
                                            body: body,
                                            media: mediaData,  // Start with an empty media array
                                            dateCreated: dateCreated,
                                            dateModified: dateModified,
                                            highlighted: highlighted,
                                            folderId: folderId,
                                            locked: locked)

                            print("Raw note data: \(rawNote)")

                            // Check if there is an image URL, then download it
                            if let imageUrlString = rawNote["media"] as? String, !imageUrlString.isEmpty, let imageUrl = URL(string: imageUrlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                // Proceed with image download
                                print("Found valid media URL: \(imageUrl)")
                                downloadGroup.enter()

                                // Download the image and replace the existing one if necessary
                                downloadImage(from: imageUrl, forNote: note) { updatedNote in
                                    // Ensure that updatedNote is properly modified and contains a new file path
                                    if let filePath = updatedNote.media.last {
                                        // Since a note can only have one image, we replace the existing media path with the new one
                                        note.media = [filePath]  // Replace the entire media array with the new image path
                                    }

                                    // Append the updated note to the fetchedNotes array
                                    fetchedNotes.append(note)
                                    
                                    // Mark the download task as complete
                                    downloadGroup.leave()
                                }


                            } else {
                                print("No valid image URL found in note or URL is malformed")
                                fetchedNotes.append(note)  // Add the note without image data if no valid URL
                            }
                        }

                        downloadGroup.notify(queue: .main) {
                            let guestNotes = noteStore.notes
                            let guestFolders = noteStore.folders

                            var mergedNotes = guestNotes + fetchedNotes
                            var mergedFolders = guestFolders + fetchedFolders

                            let uniqueNotes = Dictionary(mergedNotes.map { ($0.id, $0) }, uniquingKeysWith: { $1 }).values
                            let uniqueFolders = Dictionary(mergedFolders.map { ($0.id, $0) }, uniquingKeysWith: { $1 }).values

                            mergedNotes = Array(uniqueNotes)
                            mergedFolders = Array(uniqueFolders)

                            noteStore.notes = mergedNotes
                            noteStore.folders = mergedFolders

                            // Debug print to check media
                            for note in mergedNotes {
                                print("Note \(note.id): \(note.media.isEmpty ? "No media" : "Has media")")
                            }

                            mergedFolders.forEach { folder in
                                noteStore.addFolderToServer(folder: folder, userId: userIdString)
                            }

                            mergedNotes.forEach { note in
                                noteStore.addNoteOnServer(note: note, userId: userIdString) { result in
                                    switch result {
                                    case .success:
                                        print("Saved note to server: \(note.text)")
                                    case .failure(let error):
                                        print("Failed to save note to server: \(error.localizedDescription)")
                                    }
                                }
                            }

                            loggedInUser = username
                            showNotes = true
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            UserDefaults.standard.set(username, forKey: "loggedInUser")
                            UserDefaults.standard.set(userId, forKey: "userId")

                            if let encodedNotes = try? JSONEncoder().encode(mergedNotes) {
                                UserDefaults.standard.set(encodedNotes, forKey: "savedNotes")
                            }

                            if let encodedFolders = try? JSONEncoder().encode(mergedFolders) {
                                UserDefaults.standard.set(encodedFolders, forKey: "savedFolders")
                            }

                            showSafari = false
                            print("Login successful with username: \(username), userId: \(userId), \(mergedNotes.count) notes, and \(mergedFolders.count) folders")
                        }

                    } catch {
                        print("Failed to decode notes or folders data: \(error)")
                    }
                } else {
                    print("Failed to Base64 decode the notes or folders data")
                }
            }
        }
    }






    private func downloadImage(from url: URL, forNote note: Note, completion: @escaping (Note) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                // Save image to the Documents directory (you can save and get the file path here)
                if let filePath = self.saveImageToDocuments(image: image, note: note) {
                    print("Image saved to disk at: \(filePath)")

                    // Update the note's media with the new file path
                    var updatedNote = note
                    updatedNote.media = [filePath]  // Replace existing media with the new image path

                    // Return the updated note via the completion handler
                    completion(updatedNote)
                } else {
                    print("Failed to save image.")
                    completion(note)  // Return the note unmodified in case of failure
                }
            } else {
                print("Failed to download image.")
                completion(note)  // Return the note unmodified in case of failure
            }
        }
        task.resume()
    }




    
    private func saveImageToDocuments(image: UIImage, note: Note) -> String? {
        // Use the note's UUID as the image file name
        let fileName = "\(note.id.uuidString).png"  // Name the file after the note's UUID, ensuring it's unique to the note.
        guard let imageData = image.pngData() else { return nil }  // Save as PNG
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path  // Return file path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }







    private func resetToInitialState() {
        loggedInUser = nil
        showNotes = false

        // Remove UserDefaults data
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
        UserDefaults.standard.removeObject(forKey: "savedNotes")
        UserDefaults.standard.removeObject(forKey: "savedFolders")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")

        // Remove all stored images NEEDS TESTING
        //deleteAllStoredImages()

        print("App state reset to initial state.")
    }
    
    
    
    private func deleteAllStoredImages() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs where fileURL.pathExtension == "png" {
                try fileManager.removeItem(at: fileURL)
            }
            print("All images deleted from local storage.")
        } catch {
            print("Error deleting images: \(error)")
        }
    }

    
    


    private func fetchUserData() {
        guard let userId = UserDefaults.standard.value(forKey: "userId") as? Int else {
            print("No logged-in user ID found. Skipping data fetch.")
            return
        }

        print("Fetching data for logged-in user: \(userId)")

        NetworkService.shared.fetchNotes(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let json):
                    if let notesArray = json["notes"] as? [[String: Any]] {
                        var fetchedNotes: [Note] = []
                        let dispatchGroup = DispatchGroup()

                        print("Notes array: \(notesArray)")

                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSS"

                        for noteDict in notesArray {
                            print("Parsing note: \(noteDict)")

                            if let idString = noteDict["id"] as? String,
                               let text = noteDict["text"] as? String,
                               let body = noteDict["body"] as? String,
                               let dateCreatedString = noteDict["dateCreated"] as? String,
                               let dateModifiedString = noteDict["dateModified"] as? String,
                               let locked = noteDict["locked"] as? Bool,
                               let highlighted = noteDict["highlighted"] as? Bool {

                                let folderIdString = noteDict["folderId"] as? String
                                let imageUrlString = noteDict["media"] as? String // Check for image URL

                                let dateCreated = dateFormatter.date(from: dateCreatedString) ?? Date()
                                let dateModified = dateFormatter.date(from: dateModifiedString) ?? Date()

                                // Initialize media array (it will hold the file paths for images)
                                let mediaData: [String] = []

                                // Create the note object
                                var note = Note(id: UUID(uuidString: idString) ?? UUID(),
                                                text: text,
                                                body: body,
                                                media: mediaData,
                                                dateCreated: dateCreated,
                                                dateModified: dateModified,
                                                highlighted: highlighted,
                                                folderId: folderIdString != nil ? UUID(uuidString: folderIdString!) ?? UUID() : nil,
                                                locked: locked)

                                // Check for the image URL and download if present
                                if let imageUrlString = imageUrlString, let imageUrl = URL(string: imageUrlString) {
                                    dispatchGroup.enter() // Start tracking image download

                                    // Download the image and update the media array
                                    downloadImage(from: imageUrl, forNote: note) { updatedNote in
                                        if let filePath = updatedNote.media.first {
                                            // Clear previous media (if any) and append the new file path
                                            note.media = [filePath] // Ensures only one image is stored
                                        }

                                        // Append the updated note to the list
                                        fetchedNotes.append(note) // Add the note (with media) to the fetchedNotes array

                                        dispatchGroup.leave() // Mark this download as finished
                                    }
                                } else {
                                    // If no image URL, just append the note without media
                                    fetchedNotes.append(note)
                                }
                            } else {
                                print("Error: Missing fields in note: \(noteDict)")
                            }
                        }

                        // Wait for all image downloads to complete
                        dispatchGroup.notify(queue: .main) {
                            noteStore.notes = fetchedNotes
                            print("Fetched \(fetchedNotes.count) notes from server.")

                            if let encodedNotes = try? JSONEncoder().encode(fetchedNotes) {
                                UserDefaults.standard.set(encodedNotes, forKey: "savedNotes")
                                print("Saved notes to UserDefaults")
                            }
                        }
                    } else {
                        print("Error: No notes found in the response.")
                        //resetToInitialState()
                    }

                case .failure(let error):
                    print("Failed to fetch notes from server: \(error.localizedDescription)")
                    //esetToInitialState()
                }
            }
        }
    }



}

