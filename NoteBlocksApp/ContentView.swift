import SwiftUI

struct ContentView: View {
    @ObservedObject var noteStore = NoteStore()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var newNoteText = ""
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var selectedSearchCriteria: SearchCriteria = .text
    @State private var ipAddress = ""
    @Binding var showSafari: Bool
    @State private var showIPInputModal = false // State to control IP modal
    @State private var showLogoutConfirmation = false // State for logout confirmation alert

    let username: String
    var onLogout: () -> Void

    enum SearchCriteria {
        case text, date
    }

    var filteredNotes: [Note] {
        noteStore.notes.filter { note in
            switch selectedSearchCriteria {
            case .text:
                return searchText.isEmpty || note.text.localizedCaseInsensitiveContains(searchText)
            case .date:
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                let dateString = formatter.string(from: note.dateCreated)
                return searchText.isEmpty || dateString.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Check network only when the user is logged in
                if username != "Guest" && !networkMonitor.isConnected {
                    VStack {
                        Text("No internet connection")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                } else {
                    VStack {
                        HStack {
                            Text("Logged in as \(username)")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                                .padding()

                            if username != "Guest" {
                                Button("Log Out") {
                                    // Show confirmation alert
                                    showLogoutConfirmation = true
                                }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding(.vertical, 8)
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
                            }

                            Spacer()
                        }
                        .padding()

                        VStack {
                            HStack {
                                NavigationLink(destination: ArchiveView(noteStore: noteStore)) {
                                    Text("Archive")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .padding(.vertical, 8)
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
                                }

                                if username == "Guest" {
                                    Button(action: {
                                        showIPInputModal = true
                                    }) {
                                        Text("Log In")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .padding(.vertical, 8)
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
                                    }
                                    .sheet(isPresented: $showIPInputModal) {
                                        IPInputView(ipAddress: $ipAddress)
                                    }
                                }
                            }
                        }

                        HStack {
                            TextField("Search notes", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            Menu {
                                Button(action: {
                                    selectedSearchCriteria = .text
                                }) {
                                    HStack {
                                        Text("Search by Text")
                                        if selectedSearchCriteria == .text {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: {
                                    selectedSearchCriteria = .date
                                }) {
                                    HStack {
                                        Text("Search by Date")
                                        if selectedSearchCriteria == .date {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                ZStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.black)
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .padding()
                            }
                        }

                        HStack {
                            TextField("Enter new note", text: $newNoteText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            Button(action: {
                                if !newNoteText.isEmpty {
                                    noteStore.addNote(newNoteText)
                                    newNoteText = ""
                                    dismissKeyboard()
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }

                        ZStack {
                            if filteredNotes.isEmpty {
                                Image("menu")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 280, maxHeight: 280)
                                    .ignoresSafeArea()
                                    .opacity(0.9)
                            }

                            List {
                                ForEach(filteredNotes) { note in
                                    if !note.isArchived {
                                        ZStack {
                                            NavigationLink(destination: EditNoteView(note: $noteStore.notes[noteStore.notes.firstIndex(where: { $0.id == note.id })!])) {
                                                EmptyView()
                                            }
                                            .opacity(0)

                                            HStack {
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        Text(note.text)
                                                            .font(.headline)
                                                    }
                                                    Text("Created: \(formattedDate(note.dateCreated))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)

                                                    Text("Modified: \(formattedDate(note.dateModified))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }

                                                Spacer()
                                                if note.hasReminder {
                                                    Image(systemName: "clock")
                                                        .foregroundColor(.blue)
                                                }
                                                if note.highlighted {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                }
                                .onDelete(perform: noteStore.deleteNote)
                            }
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Network Connection Lost"),
                            message: Text("Changes won't be saved on the cloud, be sure to save the new notes as soon as you reconnect."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    .alert(isPresented: $showLogoutConfirmation) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                onLogout()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .navigationTitle("Notes")
                    .navigationBarItems(trailing: EditButton())
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
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

