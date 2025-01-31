import SwiftUI
import UserNotifications

struct EditNoteView: View {
    @Binding var note: Note
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteStore: NoteStore

    @State private var editedText: String = ""
    @State private var reminderDate: Date? = nil
    @State private var showingReminderSheet: Bool = false
    @State private var selectedFolderId: UUID?

    var body: some View {
        VStack {
            TextField("Edit note", text: $editedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                    Text("Folder:")
                        .font(.body) // You can customize the font style here
                    
                    Picker("Select Folder", selection: $selectedFolderId) {
                        Text("None").tag(UUID?.none)  // None option with a UUID?.none tag
                        ForEach(noteStore.folders, id: \.id) { folder in
                            Text(folder.name).tag(folder.id as UUID?)  // Folder option with UUID? tag
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing) // Optional: add padding on the right if needed
                }
                .padding(.horizontal)

            Button(action: { showingReminderSheet.toggle() }) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                    Text("Set Reminder")
                        .foregroundColor(.primary)
                }
            }
            .padding()

            // Check if reminderDate is set and display the date
            if let reminderDate = reminderDate {
                Text("Reminder set for: \(reminderDate, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

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

            Button(action: toggleHighlight) {
                HStack {
                    Image(systemName: note.highlighted ? "star.fill" : "star")
                        .foregroundColor(note.highlighted ? .yellow : .gray)
                        .font(.system(size: 24))
                    Text(note.highlighted ? "Unhighlight" : "Highlight")
                        .foregroundColor(Color.primary)
                }
            }
            .padding()

            Button(action: saveNote) {
                Text("Save")
                    .bold()
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Edit Note")
        .onAppear {
            editedText = note.text
            reminderDate = note.reminderDate // Restore reminder date
            noteStore.loadFolders()
            selectedFolderId = note.folderID
            print("Folders in picker: \(noteStore.folders)")
        }
        .sheet(isPresented: $showingReminderSheet) {
            ReminderPicker(reminderDate: $reminderDate)
        }
    }

    private func saveNote() {
        note.text = editedText
        
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

    private func toggleHighlight() {
        noteStore.toggleHighlight(note)
        note.highlighted.toggle()
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

