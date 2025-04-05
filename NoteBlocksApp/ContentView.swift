import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: Double
        switch hex.count {
        case 6: // RGB (no alpha)
            (a, r, g, b) = (1, Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        case 8: // RGBA
            (a, r, g, b) = (Double((int >> 24) & 0xFF) / 255, Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        default:
            (a, r, g, b) = (1, 1, 1, 1) // Default to white if invalid
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}


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
    
    @State private var selectedImage: UIImage? = nil
    @State private var showFullScreenImage = false
    
    @State private var isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")  // Track color mode
    
    @State private var randomImageIndex = Int.random(in: 0..<7)

        private let profileImages = [
            "profile1", "profile2", "profile3",
            "profile4", "profile5", "profile6", "profile7"
        ]

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
        noteStore.notes
            .filter { note in
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
            .sorted {
                if $0.highlighted == $1.highlighted {
                    return $0.dateModified > $1.dateModified
                }
                return $0.highlighted && !$1.highlighted
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
                
                Spacer()
                    .onAppear {
                        randomImageIndex = Int.random(in: 0..<7)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        if isDarkMode {
                                            windowScene.windows.first?.overrideUserInterfaceStyle = .dark
                                        } else {
                                            windowScene.windows.first?.overrideUserInterfaceStyle = .light
                                        }
                                    }
                    }
                bottomTextWithIcon
            }
        }
    }

    private var noConnectionView: some View {
        VStack {
            
            Image("wifi")
                .resizable()
                .scaledToFit()
                .frame(width: 275, height: 275)
                .cornerRadius(10)
                .padding(.top, 1)
            
            Text("No internet connection")
                .font(.headline)
                .foregroundColor(.black)
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
        .navigationBarItems(trailing: HStack {
            // Toggle Mode Button
            Button(action: {
                isDarkMode.toggle() // Toggle between light and dark mode
                
                // Save the current mode to UserDefaults
                UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
                
                // Get the active UIWindowScene
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    if isDarkMode {
                        windowScene.windows.first?.overrideUserInterfaceStyle = .dark
                    } else {
                        windowScene.windows.first?.overrideUserInterfaceStyle = .light
                    }
                }
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .foregroundColor(.primary)
            }
            EditButton()
        })
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
        .onChange(of: showFullScreenImage) { oldValue, newValue in
                    if newValue {
                        print("Full-screen image view triggered!")  // Debugging line
                    }
                }
        .fullScreenCover(isPresented: $showFullScreenImage, content: {
            FullScreenImageView(showFullScreenImage: $showFullScreenImage, image: selectedImage)
        })

    }

    private var navigationButtons: some View {
        VStack {
            HStack {
                NavigationLink(destination: ArchiveView(noteStore: noteStore)) {
                    navigationButton(icon: "archivebutton", label: "Archive")
                }

                NavigationLink(destination: FolderView().environmentObject(noteStore)) {
                    navigationButton(icon: "storage" , label: "Folders")
                }

                if username == "Guest" {
                    logInButton
                } else {
                    profileButton
                    
                    NavigationLink(destination: SocialView()) {  // Friends Navigation Button
                                        navigationButton(icon: "share", label: "Explore")
                                    }
                }
            }
        }
    }


    private func navigationButton(icon: String, label: String) -> some View {
        VStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(Color.primary)
                .scaleEffect(icon == "storage" ? 1.1 : 1.0)

            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.primary)
        }
        .frame(width: 80, height: 80)
        .background(Color.clear)
    }
    
    private var profileButton: some View {
        Button(action: {
            randomImageIndex = Int.random(in: 0..<7)
            showProfileModal = true // Trigger the modal when tapped
        }) {
            VStack {
                Image(profileImages[randomImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(1.3)
                    

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
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
        }
    }
    


    private var logInButton: some View {
        Button(action: {
            randomImageIndex = Int.random(in: 0..<7)
            showIPInputModal = true
        }) {
            VStack {
                Image(profileImages[randomImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(1.3)

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

            TextField("Search card", text: $searchText)
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
            
            TextField("Enter new card name", text: $newNoteText)
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
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#FFB27F"), Color(hex: "#FFB27F")]), // Orange and Yellow in Hex
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 35, height: 35)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "#000000") : Color(hex: "#FFFFFF"))
                )
                .shadow(color: Color(hex: "#FFB27F").opacity(0.2), radius: 2, x: 0, y: 2)



        }
        .padding(4)
    }

    private var notesList: some View {
        ZStack {
            if filteredNotes.isEmpty {
                Image("menu")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 290, maxHeight: 290)
                    .ignoresSafeArea()
                    .opacity(0.9)
            }

            List {
                ForEach(filteredNotes.sorted {
                    if $0.highlighted == $1.highlighted {
                        return $0.dateModified > $1.dateModified
                    }
                    return $0.highlighted && !$1.highlighted
                }) { note in
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
            NavigationLink(destination: EditNoteView(note: $noteStore.notes[noteStore.notes.firstIndex(where: { $0.id == note.id })!], username: username)) {
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
        HStack {
            // Show image if note has media
            if let firstImagePath = note.media.first, let uiImage = UIImage(contentsOfFile: firstImagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 65, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.trailing, 8)
                    .blur(radius: note.locked ? 10 : 0)
                    .onTapGesture {
                        if !note.locked { // Optional: Only allow opening if unlocked
                            selectedImage = uiImage
                            showFullScreenImage = true
                        }
                    }
            }


            VStack(alignment: .leading) {
                Text(note.text)
                    .font(.headline)

                Text("Created: \(formattedDate(note.dateCreated))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

struct FullScreenImageView: View {
    @Binding var showFullScreenImage: Bool  // Binding to control dismissal
    let image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()  // Background color for full screen

            // Display the image if available
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Fallback message if image is nil
                Text("No image available")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            }

            // Close Button at the top-right corner
            HStack {
                Spacer()
                Button(action: {
                    showFullScreenImage = false  // Dismiss the full-screen image
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                        .padding()
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)  // Align to the top-right corner
        }
    }
}




private var bottomTextWithIcon: some View {
    HStack {
        // Copyright Info
        Text("© 2025 NoteBlocks")
            .font(.system(size: 12))  // Same font size for consistency
            .foregroundColor(.gray)
    }
    .frame(maxWidth: .infinity, alignment: .bottom)
    .padding(.horizontal, 20)  // Add horizontal padding to give it space
    .background(Color.clear)  // Remove the color from HStack background
    .foregroundColor(.clear)
}



private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

