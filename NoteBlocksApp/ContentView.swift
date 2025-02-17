import SwiftUI

struct ContentView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.colorScheme) var colorScheme

    @State private var newNoteText = ""
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var selectedSearchCriteria: SearchCriteria = .text
    @State private var ipAddress = ""
    @State private var showIPInputModal = false
    @State private var showProfileModal = false
    @State private var showLogoutConfirmation = false

    let username: String
    var onLogout: () -> Void = {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }

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
                if username != "Guest" && !networkMonitor.isConnected {
                    noConnectionView
                } else {
                    loggedInView
                }
            }
        }
    }

    private var noConnectionView: some View {
        VStack {
            Text("No internet connection")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()

            Button(action: {
                onLogout()
                showAlert = false
            }) {
                Text("Continue Offline")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 150)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var loggedInView: some View {
        VStack {
            userHeader
            mainContent
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Network Connection Lost"),
                message: Text("Changes won't be saved on the cloud, be sure to save the new notes as soon as you reconnect."),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Home")
        .navigationBarItems(trailing: EditButton())
    }

    private var userHeader: some View {
        HStack {
            Text("Logged in as \(username)")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .padding()

            Spacer()
        }
        .padding()
    }

    private var mainContent: some View {
        VStack {
            navigationButtons
            searchAndCreateNoteFields
            notesList
        }
    }

    private var navigationButtons: some View {
        VStack {
            HStack {
                NavigationLink(destination: ArchiveView(noteStore: noteStore)) {
                    navigationButton(icon: "archivebox", label: "Archive")
                }

                NavigationLink(destination: FolderView().environmentObject(noteStore)) {
                    navigationButton(icon: "folder", label: "Folders")
                }

                if username == "Guest" {
                    logInButton
                } else {
                    profileButton
                    
                    NavigationLink(destination: SocialView()) {  // Friends Navigation Button
                                        navigationButton(icon: "globe", label: "Explore")
                                    }
                }
            }
        }
    }


    private func navigationButton(icon: String, label: String) -> some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(Color.primary)

            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.primary)
        }
        .frame(width: 80, height: 80)
        .background(Color.clear)
    }
    
    private var profileButton: some View {
        Button(action: {
            showProfileModal = true // Trigger the modal when tapped
        }) {
            VStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.primary)

                Text("Profile")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
            }
            .frame(width: 80, height: 80)
            .background(Color.clear)
        }
        .sheet(isPresented: $showProfileModal) {
            NavigationView {
                ProfileView(username: username, onLogout: onLogout, showLogoutConfirmation: $showLogoutConfirmation)
                .transition(.move(edge: .bottom))
            }
        }
    }
    


    private var logInButton: some View {
        Button(action: {
            showIPInputModal = true
        }) {
            VStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.primary)

                Text("Log In")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
            }
            .frame(width: 80, height: 80)
            .background(Color.clear)
        }
        .sheet(isPresented: $showIPInputModal) {
            IPInputView()
        }
    }

    private var searchAndCreateNoteFields: some View {
        VStack(spacing: 10) {
            searchFields
            createNoteFields
        }
    }

    private var searchFields: some View {
        HStack {
            searchTextField
            criteriaMenu
            Spacer()
        }
    }

    private var searchTextField: some View {
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
    }

    private var criteriaMenu: some View {
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
    }

    private var createNoteFields: some View {
        HStack {
            noteTextField
            addNoteButton
            Spacer()
        }
    }

    private var noteTextField: some View {
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
    }

    private var addNoteButton: some View {
        Button(action: {
            if !newNoteText.isEmpty {
                noteStore.addNote(newNoteText)
                newNoteText = ""
                dismissKeyboard()
                noteStore.loadNotes()
            }
        }) {
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 35, height: 35)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                )
                .shadow(color: Color.orange.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .padding(4)
    }

    private var notesList: some View {
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
                        noteRow(note: note)
                    }
                }
                .onDelete(perform: noteStore.deleteNote)
            }
        }
    }

    private func noteRow(note: Note) -> some View {
        ZStack {
            // NavigationLink that directly passes a binding to the note
                NavigationLink(destination: EditNoteView(note: $noteStore.notes[noteStore.notes.firstIndex(where: { $0.id == note.id })!])) {
                    EmptyView()
                }
                .opacity(0)

            
            HStack {
                noteInfo(note: note)
                noteIcons(note: note)
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())  // Make the whole row tappable
    }


    private func noteInfo(note: Note) -> some View {
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
    }

    private func noteIcons(note: Note) -> some View {
        HStack {
            if note.hasReminder {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
            }

            if note.highlighted {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }

            if note.locked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
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

