import SwiftUI
import UserNotifications
import LocalAuthentication

struct EditNoteView: View {
    @Binding var note: Note
    let username: String
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteStore: NoteStore

    @State private var editedText: String = ""
    @State private var reminderDate: Date? = nil
    @State private var showingReminderSheet: Bool = false
    @State private var selectedFolderId: UUID?
    
    @State private var editedBody: String = ""
    @State private var editedMedia: [Data] = []
    @State private var showingMediaSheet: Bool = false
    @State private var showLoginModal = false
    

    var body: some View {
        VStack {
            HStack {
                
                Image(systemName: "pencil")
                    .foregroundColor(.gray)
                
                TextField("Rename block", text: $editedText)
                    .foregroundColor(.primary)
                    .padding(5)
            }
            .padding(3)
            .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
            .padding(.horizontal, 10)
            
            HStack {
                Image("folder") // Replace with your actual image asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27) // Match system image size
                        .foregroundColor(.primary)
                Text("Folder:")
                    .font(.body)
                
                // Custom Menu Button
                Menu {
                    Button(action: {
                        selectedFolderId = nil // Set to "None"
                    }) {
                        Text("None")
                    }
                    
                    ForEach(noteStore.folders, id: \.id) { folder in
                        Button(action: {
                            selectedFolderId = folder.id
                        }) {
                            Text(folder.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedFolderId == nil ? "None" : noteStore.folders.first(where: { $0.id == selectedFolderId })?.name ?? "Select Folder")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .frame(maxWidth: 120) // Adjust width as needed
                }
            }
            .padding(.horizontal)
            
            
            NoteBody(text: $editedBody)
                .padding(.top, 3)   // Removed any additional top padding
                .padding(.bottom, 3)

            
            VStack  {
                HStack {
                    Button(action: { showingReminderSheet.toggle() }) {
                        VStack {
                            Image("reminder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Base size
                                .scaleEffect(1.4) // Increase size without affecting layout
                            
                            Text("Reminder")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())

                    Button(action: toggleLock) {
                        VStack {
                            Image(systemName: note.locked ? "lock.fill" : "lock.open")
                                .foregroundColor(note.locked ? .yellow : .gray)
                                .font(.system(size: 24))
                            Text(note.locked ? "Locked" : "Unlocked")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())
                }
                .padding(.horizontal)

                HStack {
                    Button(action: { showingMediaSheet.toggle() }) {
                        VStack {
                            Image("imagemenu")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Base size
                                .scaleEffect(1.4) // Increase size without affecting layout
                            
                            Text("Media")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())
                    
                    Button(action: {
                        if username == "Guest" { // Replace with actual authentication logic
                            showLoginModal.toggle()
                        } else {
                            // Future functionality for logged-in users
                        }
                    }) {
                        VStack {
                            Image("share")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Base size
                                .scaleEffect(1.4)
                            Text("Share")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())
                    .sheet(isPresented: $showLoginModal) {
                        GuestLoginPromptView() // A modal for guest users
                    }
                    
                    Button(action: toggleHighlight) {
                        VStack {
                            Image(systemName: note.highlighted ? "star.fill" : "star")
                                .foregroundColor(note.highlighted ? .yellow : .gray)
                                .font(.system(size: 24))
                            Text(note.highlighted ? "Unhighlight" : "Highlight")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())
                }
                .padding(.horizontal)
                
                HStack {
                    
                    Button(action: { if username == "Guest" { // Replace with actual authentication logic
                        showLoginModal.toggle()
                    } else {
                        // Future functionality for logged-in users
                    } }) {
                        VStack {
                            Image("paperplane")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Base size
                                .scaleEffect(1.5) // Increase size without affecting layout
                                .foregroundColor(.orange)
                            
                            Text("Send to")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())


                    
                    Button(action: saveNote) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 24))
                            Text("Save")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(CustomButtonStyle())
                    }
                .padding(.horizontal)
                
                if let reminderDate = reminderDate {
                    VStack {
                        Text("Reminder set for: \(reminderDate, formatter: dateFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        Button("Clear Reminder") {
                            self.reminderDate = nil
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .bold()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 20) // Adjust spacing below buttons
                }

                Spacer()
            }

        }
        .navigationTitle("View Block")
        .onAppear {
            if note.locked {
                // Ask for authentication if the note is locked
                authenticateUser { success in
                    if success {
                        // Authentication succeeded, allow access to the note
                        editedText = note.text
                        
                        editedBody = note.body
                        editedMedia = note.media
                        
                        reminderDate = note.reminderDate
                        noteStore.loadFolders()
                        selectedFolderId = note.folderID
                    } else {
                        // If authentication fails, exit or show an error
                        presentationMode.wrappedValue.dismiss() // Or show an alert
                    }
                }
            } else {
                // If the note is not locked, proceed as usual
                editedText = note.text
                
                editedBody = note.body
                editedMedia = note.media
                
                reminderDate = note.reminderDate
                noteStore.loadFolders()
                selectedFolderId = note.folderID
            }
        }

        .sheet(isPresented: $showingReminderSheet) {
            ReminderPicker(reminderDate: $reminderDate)
        }
        .sheet(isPresented: $showingMediaSheet) {
                    MediaPickerView(noteID: note.id, editedMedia: $editedMedia)
                .presentationDetents([.height(450), .large])
                .presentationDragIndicator(.visible)
                }
    }

    private func saveNote() {
        note.text = editedText
        
        note.body = editedBody
        note.media = editedMedia
        
        if let folderId = selectedFolderId {
            note.folderID = folderId
        } else {
            note.folderID = nil
        }
        
        note.dateModified = Date()
        note.reminderDate = reminderDate
        noteStore.updateNoteText($note, with: editedText)

        if let reminderDate = reminderDate {
            scheduleNotification(for: note, at: reminderDate)
        }

        presentationMode.wrappedValue.dismiss()
    }
    
    private func toggleLock() {
        if note.locked {
            // If already locked, unlock it (no need for authentication)
            note.locked = false
        } else {
            // If not locked, authenticate the user to lock it
            authenticateUser { success in
                if success {
                    note.locked = true
                } else {
                    // If authentication failed, show an alert or feedback
                    print("Authentication failed!")
                }
            }
        }
    }


    private func toggleHighlight() {
        //note.highlighted.toggle()
        noteStore.toggleHighlight(note)
    }

    private func scheduleNotification(for note: Note, at date: Date) {
        if note.isArchived {
            print("Note is archived, skipping notification.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Reminder for your note"
        content.body = note.text
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: note.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}


struct ReminderPicker: View {
    @Binding var reminderDate: Date?

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Set Reminder",
                    selection: Binding(
                        get: { reminderDate ?? Date() }, // Use current date if reminderDate is nil
                        set: { reminderDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

                Spacer()

                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
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
                .offset(y: -150)
            }
            .navigationTitle("Select Date & Time")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private func authenticateUser(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?

    // Check if Face ID or Touch ID is available
    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Please authenticate to lock the note") { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    completion(false)
                    // Handle authentication failure (e.g., alert the user)
                    print(authenticationError?.localizedDescription ?? "Authentication failed")
                }
            }
        }
    } else {
        // Handle error if biometrics are not available
        completion(false)
        print(error?.localizedDescription ?? "Biometrics not available")
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

