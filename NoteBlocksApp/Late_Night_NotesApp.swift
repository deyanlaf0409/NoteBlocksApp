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

    // Add a state to track the local network permission request
    @State private var localNetworkPermissionRequested = false
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // Show the main content if logged in, else show the intro view
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

                        //networkRule.requestLocalNetworkPermission()
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
               let userId = queryItems.first(where: { $0.name == "user_id" })?.value, // Retrieve user_id
               let notesString = queryItems.first(where: { $0.name == "notes" })?.value {

                // Base64-decode the notes string
                if let decodedNotesData = Data(base64Encoded: notesString) {
                    // Initialize a JSONDecoder and set up the date decoding strategy
                    let decoder = JSONDecoder()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSS"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)

                    // Custom decoding for the highlighted field
                    do {
                        let rawNotes = try JSONSerialization.jsonObject(with: decodedNotesData) as? [[String: Any]]
                        
                        let notes = rawNotes?.compactMap { rawNote -> Note? in
                            guard let idString = rawNote["id"] as? String,
                                  let text = rawNote["text"] as? String,
                                  let dateCreatedString = rawNote["dateCreated"] as? String,
                                  let dateModifiedString = rawNote["dateModified"] as? String,
                                  let highlightedString = rawNote["highlighted"] as? String else {
                                return nil
                            }
                            
                            let dateCreated = dateFormatter.date(from: dateCreatedString) ?? Date()
                            let dateModified = dateFormatter.date(from: dateModifiedString) ?? Date()
                            let highlighted = (highlightedString == "t") // Convert "t" or "f" to Bool
                            
                            return Note(id: UUID(uuidString: idString) ?? UUID(),
                                        text: text,
                                        dateCreated: dateCreated,
                                        dateModified: dateModified,
                                        highlighted: highlighted)
                        } ?? []

                        // Update app state to reflect the user login
                        loggedInUser = username
                        showNotes = true // Switch to show ContentView

                        // Save login state
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "loggedInUser")
                        UserDefaults.standard.set(userId, forKey: "userId") // Save userId to UserDefaults

                        // Save notes in UserDefaults
                        if let encodedNotes = try? JSONEncoder().encode(notes) {
                            UserDefaults.standard.set(encodedNotes, forKey: "savedNotes")
                        }

                        showSafari = false
                        
                        print("Login successful with username: \(username), userId: \(userId), and \(notes.count) notes")
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
        // Reset properties
        loggedInUser = nil
        showNotes = false

        // Clear UserDefaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")

        print("App state reset to initial state.")
    }

}


