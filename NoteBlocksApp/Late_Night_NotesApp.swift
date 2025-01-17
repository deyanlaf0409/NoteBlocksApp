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
                ContentView(showSafari: $showSafari, username: loggedInUser ?? "Guest", onLogout: resetToInitialState)
                    .environmentObject(noteStore)
                    .environmentObject(networkMonitor)
                    .onOpenURL { url in
                        handleDeepLink(url: url)
                    }
                    .onAppear {
                        let dummyNote = Note(id: UUID(), text: "Test Note", dateCreated: Date(), dateModified: Date(), highlighted: false)
                        let userId = "12345"

                        noteStore.addNoteOnServer(note: dummyNote, userId: userId) { result in
                            switch result {
                            case .success:
                                print("Successfully triggered the local network permission dialog.")
                            case .failure(let error):
                                print("Failed to trigger local network permission: \(error.localizedDescription)")
                            }
                        }

                        fetchUserData()
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
               let notesString = queryItems.first(where: { $0.name == "notes" })?.value {

                noteStore.loadNotes()
                print("Loaded guest notes: \(noteStore.notes.map { $0.text })")

                if let decodedNotesData = Data(base64Encoded: notesString) {
                    let decoder = JSONDecoder()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSS"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)

                    do {
                        let rawNotes = try JSONSerialization.jsonObject(with: decodedNotesData) as? [[String: Any]]

                        let fetchedNotes = rawNotes?.compactMap { rawNote -> Note? in
                            guard let idString = rawNote["id"] as? String,
                                  let text = rawNote["text"] as? String,
                                  let dateCreatedString = rawNote["dateCreated"] as? String,
                                  let dateModifiedString = rawNote["dateModified"] as? String,
                                  let highlightedString = rawNote["highlighted"] as? String else {
                                return nil
                            }

                            let dateCreated = dateFormatter.date(from: dateCreatedString) ?? Date()
                            let dateModified = dateFormatter.date(from: dateModifiedString) ?? Date()
                            let highlighted = (highlightedString == "t")

                            return Note(id: UUID(uuidString: idString) ?? UUID(),
                                        text: text,
                                        dateCreated: dateCreated,
                                        dateModified: dateModified,
                                        highlighted: highlighted)
                        } ?? []

                        let guestNotes = noteStore.notes
                        var mergedNotes = guestNotes + fetchedNotes

                        let uniqueNotes = Dictionary(mergedNotes.map { ($0.id, $0) }, uniquingKeysWith: { $1 }).values
                        mergedNotes = Array(uniqueNotes)

                        noteStore.notes = mergedNotes
                        print("Merged notes: \(mergedNotes.map { $0.text })")

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

                        showSafari = false
                        print("Login successful with username: \(username), userId: \(userId), and \(mergedNotes.count) notes")
                    } catch {
                        print("Failed to decode notes data: \(error)")
                    }
                } else {
                    print("Failed to Base64 decode the notes data")
                }
            } else {
                print("Login failed or invalid deep link")
            }
        }
    }

    private func resetToInitialState() {
        loggedInUser = nil
        showNotes = false

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")

        print("App state reset to initial state.")
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
                    // Log the raw response
                    if let rawResponse = String(data: try! JSONSerialization.data(withJSONObject: json), encoding: .utf8) {
                        print("Raw response: \(rawResponse)")
                    }

                    // Check if the response has a 'status' field and that it is 'success'
                    guard let status = json["status"] as? String, status == "success" else {
                        print("Error: Invalid status in response or no notes found.")
                        return
                    }

                    // Extract the user information
                    if let userDict = json["user"] as? [String: Any],
                       let username = userDict["username"] as? String {
                        loggedInUser = username
                        print("Username: \(username)")
                    }

                    // Extract the notes array
                    if let notesArray = json["notes"] as? [[String: Any]] {
                        var fetchedNotes: [Note] = []
                        
                        // Debugging: Check the structure of each note
                        print("Notes array: \(notesArray)")

                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSS"
                        
                        for noteDict in notesArray {
                            // Debugging: Check individual note
                            print("Parsing note: \(noteDict)")

                            if let idString = noteDict["id"] as? String,
                               let text = noteDict["text"] as? String,
                               let dateCreatedString = noteDict["dateCreated"] as? String,
                               let dateModifiedString = noteDict["dateModified"] as? String,
                               let highlighted = noteDict["highlighted"] as? Bool {
                                
                                let dateCreated = dateFormatter.date(from: dateCreatedString) ?? Date()
                                let dateModified = dateFormatter.date(from: dateModifiedString) ?? Date()

                                // Create a new Note object from the dictionary
                                let note = Note(id: UUID(uuidString: idString) ?? UUID(),
                                                text: text,
                                                dateCreated: dateCreated,
                                                dateModified: dateModified,
                                                highlighted: highlighted)
                                
                                // Add the note to the array
                                fetchedNotes.append(note)
                            } else {
                                print("Error: Missing fields in note: \(noteDict)")
                            }
                        }

                        // Update the NoteStore with the fetched notes
                        noteStore.notes = fetchedNotes
                        print("Fetched \(fetchedNotes.count) notes from server.")

                        // Optionally, save the notes to UserDefaults
                        if let encodedNotes = try? JSONEncoder().encode(fetchedNotes) {
                            UserDefaults.standard.set(encodedNotes, forKey: "savedNotes")
                            print("Saved notes to UserDefaults")
                        }

                    } else {
                        print("Error: No notes found in the response.")
                    }

                case .failure(let error):
                    print("Failed to fetch notes from server: \(error.localizedDescription)")
                }
            }
        }
    }





}

