import SwiftUI
import AVFoundation

import Combine

struct FriendRequest: Identifiable, Hashable {
    var id: String
    var username: String
}

struct SharedNote: Identifiable, Hashable {
    var id: String
    var username: String
    var text: String
    var body: String
    var mediaURL: String?
    
    static func == (lhs: SharedNote, rhs: SharedNote) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id) // Ensure hash is based on `id`, or any other properties you want to ensure uniqueness.
        }
}


struct SocialView: View {
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0
    @State private var pendingRequestsCount: Int = 0
    @State private var friendRequests: [FriendRequest] = []
    @State private var alertMessage: String = ""  // Shared alert message
    @State private var showAlert: Bool = false    // Shared alert flag
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Options", selection: $selectedTab) {
                    Text("Search").tag(0)
                    Text(pendingRequestsCount > 0 ? "Requests (\(pendingRequestsCount))" : "Requests").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedTab == 0 {
                    FriendSearchView(friendRequests: $friendRequests, showAlert: $showAlert, alertMessage: $alertMessage)  // Pass bindings
                } else {
                    FriendRequestsView(friendRequests: $friendRequests, onUpdate: fetchNetworkData, showAlert: $showAlert, alertMessage: $alertMessage)
                }

                Spacer()
            }
            .navigationTitle("Network")
            .onAppear {
                fetchNetworkData()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            // Move the navigation destination here to ensure it's always available
            .navigationDestination(for: SharedNote.self) { note in
                FullNoteView(note: note)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.vertical, 3.5)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 150)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primary, Color.primary]),
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
    }

    func fetchNetworkData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

        let countParams = ["action": "count_requests", "user_id": userId]
        let listParams = ["action": "list_requests", "user_id": userId]

        // Fetch request count
        NetworkManager.shared.makeRequest(parameters: countParams) { result in
            switch result {
            case .success(let response):
                if let count = response["count"] as? Int {
                    DispatchQueue.main.async {
                        self.pendingRequestsCount = count
                    }
                }
            case .failure(let error):
                self.showAlert(message: "Failed to fetch request count: \(error.localizedDescription)")
            }
        }

        // Fetch friend requests
        NetworkManager.shared.makeRequest(parameters: listParams) { result in
            switch result {
            case .success(let response):
                if let requests = response["pending_requests"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.friendRequests = requests.compactMap {
                            if let id = $0["id"] as? String, let username = $0["username"] as? String {
                                return FriendRequest(id: id, username: username)
                            }
                            return nil
                        }
                    }
                }
            case .failure(let error):
                self.showAlert(message: "Failed to fetch friend requests: \(error.localizedDescription)")
            }
        }
    }

    func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}








struct FriendRequestsView: View {
    @Binding var friendRequests: [FriendRequest]
    var onUpdate: () -> Void
    @Binding var showAlert: Bool            // Add binding for showAlert
    @Binding var alertMessage: String       // Add binding for alertMessage
    @State private var acceptingRequest: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if friendRequests.isEmpty {
                VStack(spacing: 0) { // Set spacing to 0 to remove extra space
                    Image("requests") // Image should render here
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .opacity(0.9)
                        .padding(.top, 0) // Adjust size
                    
                    Text("No pending friend requests")
                        .foregroundColor(.gray)
                        .padding(.top, 5) // Optional: fine-tune spacing if needed
                }

            } else {
                ForEach(friendRequests) { request in
                    RequestRow(request: request, acceptingRequest: $acceptingRequest, onResponse: respondToRequest)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Request Response"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func respondToRequest(targetUsername: String, accept: Bool) {
        acceptingRequest = targetUsername
        let action = accept ? "accept_request" : "decline_request"

        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let params = ["action": action, "user_id": userId, "target_username": targetUsername]

        NetworkManager.shared.makeRequest(parameters: params) { result in
            switch result {
            case .success(let response):
                if let message = response["message"] as? String {
                    DispatchQueue.main.async {
                        self.alertMessage = message
                        self.showAlert = true
                        onUpdate()  // Update the network data after response
                    }
                }
            case .failure(let error):
                self.showAlert(message: "Request failed: \(error.localizedDescription)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.acceptingRequest = nil
        }
    }

    func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}





struct FriendSearchView: View {
    @State private var searchText: String = ""
    @Binding var friendRequests: [FriendRequest]
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @State private var showScanner: Bool = false

    @EnvironmentObject var noteStore: NoteStore  // <-- Access NoteStore from the environment

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                TextField("Enter username", text: $searchText)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                    .frame(height: 40)  // Set a consistent height for the TextField
                    .padding(.leading, 10)

                Button(action: {
                    if !searchText.isEmpty {
                        sendFriendRequest(username: searchText)
                    }
                }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.orange)
                        .font(.system(size: 17))  // Increased font size for better visibility
                        .padding(10)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .frame(width: 40, height: 40)  // Adjusted size for consistency
                }
                .disabled(searchText.isEmpty)

                Button(action: {
                    showScanner = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))  // Increased font size for better visibility
                        .padding(10)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .frame(width: 40, height: 40)  // Adjusted size for consistency
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5)


 

            // Shared Notes Feed
            if noteStore.sharedNotes.isEmpty {
                ProgressView("Loading shared notes...")
                    .onAppear {
                        fetchSharedNotes()  // Fetch if the shared notes are not already loaded
                    }
            } else {
                List(noteStore.sharedNotes) { note in  // Use sharedNotes from NoteStore
                    SharedNoteRow(note: note)
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { scannedUsername in
                showScanner = false
                sendFriendRequest(username: scannedUsername)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                searchText = ""
            }))
        }
    }

    func sendFriendRequest(username: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            showAlert(message: "User not authenticated")
            return
        }

        let params = ["action": "send_request", "user_id": userId, "target_username": username]

        NetworkManager.shared.makeRequest(parameters: params) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let message = response["message"] as? String {
                        alertMessage = message
                        showAlert = true
                    }
                case .failure(let error):
                    alertMessage = "Request failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }

    // Function to trigger fetch if not already done
    func fetchSharedNotes() {
        // Only fetch if the notes are empty
        if noteStore.sharedNotes.isEmpty {
            noteStore.fetchSharedNotes()
        }
    }
}

class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()
    
    func getImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func saveImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
 



struct SharedNoteRow: View {
    var note: SharedNote
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    @State private var isImageFullScreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) { // slightly increased spacing here for better control
            HStack {
                Text(note.username)
                    .foregroundColor(.secondary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(note.text)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            if let mediaURL = note.mediaURL, !mediaURL.isEmpty, let url = URL(string: mediaURL) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.orange))
                            .scaleEffect(1.0)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    }

                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isImageFullScreen = true
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .padding(.bottom, 0) // <-- reduced bottom padding under image
                .onAppear {
                    loadImage(from: url)
                }
                .sheet(isPresented: $isImageFullScreen) {
                    if let image = image {
                        FullScreenImageViewSocial(image: image)
                    }
                }
            }

            NavigationLink(value: note) {
                EmptyView()
            }
            .opacity(0)
        }
        .padding(.vertical, 0) // <-- tighter vertical padding
    }

    private func loadImage(from url: URL) {
        if let cachedImage = ImageCache.shared.getImage(for: url) {
            image = cachedImage
            isLoading = false
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                ImageCache.shared.saveImage(downloadedImage, for: url)
                self.image = downloadedImage
                self.isLoading = false
            }
        }.resume()
    }
}







// Full-screen image view
struct FullScreenImageViewSocial: View {
    var image: UIImage?
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("Loading image...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.orange))
            }
        }
    }
}

// Full note modal
struct FullNoteView: View {
    var note: SharedNote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(note.username)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading) // Align to the left

                Text(note.body)
                    .font(.headline)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
            }
            .padding()
        }
        .navigationBarTitle("Note Details", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.vertical, 3.5)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 150)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primary, Color.primary]),
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
    }
}














struct RequestRow: View {
    var request: FriendRequest
    @Binding var acceptingRequest: String?
    var onResponse: (String, Bool) -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .padding(.leading, 25)
            Text(request.username)
                .font(.headline)
                //.padding(.leading, 15)

            Spacer()

            HStack(spacing: 15) {
                Button(action: {
                    onResponse(request.username, true) // Removed 'accept:'
                }) {
                    Text("Accept")
                        .foregroundColor(.orange)
                }
                .disabled(acceptingRequest != nil && acceptingRequest != request.id)

                Button(action: {
                    onResponse(request.username, false) // Removed 'accept:'
                }) {
                    Text("Decline")
                        .foregroundColor(.gray)
                }
                .disabled(acceptingRequest != nil && acceptingRequest != request.id)
            }
            .padding(.trailing, 15)
        }
        .padding(.vertical, 5)
    }
}




