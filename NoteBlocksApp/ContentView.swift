import SwiftUI

struct ContentView: View {
    @ObservedObject var noteStore = NoteStore()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.colorScheme) var colorScheme
    
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

                        Button(action: {
                            // Reset app storage and log in as a guest
                            onLogout()
                            showAlert = false // Dismiss any network alert
                        }) {
                            Text("Continue Offline")
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
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                }
 else {
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
                                    VStack {
                                        Image(systemName: "archivebox") // SF Symbol for archive
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50) // Adjust size as needed
                                            .foregroundColor(Color.primary)

                                        Text("Archive")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.primary)
                                    }
                                    .frame(width: 80, height: 80) // Square shape
                                    .background(Color.clear) // Transparent background
                                }
                                
                                NavigationLink(destination: FolderView().environmentObject(noteStore)) {
                                    VStack {
                                        Image(systemName: "folder") // SF Symbol for folders
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color.primary) // Adapts to light/dark mode

                                        Text("Folders")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.primary) // Adapts to light/dark mode
                                    }
                                    .frame(width: 80, height: 80) // Square shape
                                    .background(Color.clear) // Transparent background
                                }


                                if username == "Guest" {
                                    Button(action: {
                                        showIPInputModal = true
                                    }) {
                                        VStack {
                                            Image(systemName: "person.crop.circle") // Replace with desired SF Symbol
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50) // Adjust size as needed
                                                .foregroundColor(Color.primary)

                                            Text("Log In")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(Color.primary)
                                        }
                                        .frame(width: 80, height: 80) // Makes the button square
                                        .background(Color.clear) // Transparent background
                                    }
                                    .sheet(isPresented: $showIPInputModal) {
                                        IPInputView()
                                    }

                                }
                            }
                        }

                        VStack(spacing: 10) { // Reduce space between elements
                            HStack {
                                // Search Notes TextField
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)

                                    TextField("Search block", text: $searchText)
                                        .foregroundColor(.primary)
                                        .padding(5)
                                }
                                .padding(3)
                                .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                                .padding(.horizontal, 10)

                                // Three dots button
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
                                    .padding(4)
                                }
                                
                                Spacer() // Push buttons to the right
                            }

                            HStack {
                                // Enter new block TextField
                                HStack {
                                    Image(systemName: "cube.box")
                                        .foregroundColor(.gray)

                                    TextField("Enter new block", text: $newNoteText)
                                        .foregroundColor(.primary)
                                        .padding(5)
                                }
                                .padding(3)
                                .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                                .padding(.horizontal, 10)

                                // Plus button to add new note
                                Button(action: {
                                    if !newNoteText.isEmpty {
                                        noteStore.addNote(newNoteText)
                                        newNoteText = ""
                                        dismissKeyboard()
                                        noteStore.loadNotes()
                                    }
                                }) {
                                    Circle()
                                        .fill(
                                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 35, height: 35)  // Adjust size of the circle
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 25, weight: .bold))  // Set the icon size
                                                .foregroundColor(colorScheme == .dark ? .black : .white))  // Set the icon color to white
                                    
                                        .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 4)  // Add subtle shadow for depth
                                }
                                .padding(4)  // Adjust padding as needed


                                Spacer() // Push buttons to the right
                            }
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

                                                // Check if the note has a reminder
                                                if note.hasReminder {
                                                    Image(systemName: "clock")
                                                        .foregroundColor(.blue)
                                                }

                                                // Check if the note is highlighted
                                                if note.highlighted {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow)
                                                }

                                                // Check if the note is locked
                                                if note.locked {
                                                    Image(systemName: "lock.fill")
                                                        .foregroundColor(.gray) // or any color to indicate locked state
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
                    .navigationTitle("Home")
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
