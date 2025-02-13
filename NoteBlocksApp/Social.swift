import SwiftUI

struct FriendRequest: Identifiable {
    var id: String
    var username: String
}

struct SocialView: View {
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0
    @State private var pendingRequestsCount: Int = 0
    @State private var friendRequests: [FriendRequest] = []
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack {
            Picker("Options", selection: $selectedTab) {
                Text("Search").tag(0)
                Text(pendingRequestsCount > 0 ? "Requests (\(pendingRequestsCount))" : "Requests").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == 0 {
                FriendSearchView(friendRequests: $friendRequests)  // Pass binding here
            } else {
                FriendRequestsView(friendRequests: $friendRequests, onUpdate: fetchNetworkData)
            }

            Spacer()
        }
        .navigationTitle("Network")
        .onAppear {
            fetchNetworkData()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
    @State private var acceptingRequest: String? = nil
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack {
            if friendRequests.isEmpty {
                Text("No pending friend requests")
                    .foregroundColor(.gray)
                    .padding()
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
                        onUpdate()
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
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    @Binding var friendRequests: [FriendRequest]  // Add binding to friendRequests in SocialView

    var body: some View {
        VStack {
            Text("Send friendship request")
                .font(.headline)
                .padding(.top)

            HStack {
                TextField("Enter username", text: $searchText)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                    .padding(.leading, 10)

                Button(action: {
                    if !searchText.isEmpty {
                        sendFriendRequest(username: searchText)
                    }
                }) {
                    Image(systemName: "paperplane")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                        .padding()
                }
                .disabled(searchText.isEmpty)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                searchText = "" // Clear text field after success
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
            switch result {
            case .success(let response):
                print("Success: \(response)")  // Debug print
                if let message = response["message"] as? String {
                    DispatchQueue.main.async {
                        self.alertMessage = message
                        self.showAlert = true
                        print("Alert will show with message: \(message)")  // Debug print
                    }

                    // Assuming the response includes the new request's details
                    if let newRequest = response["new_request"] as? [String: Any],
                       let id = newRequest["id"] as? String,
                       let username = newRequest["username"] as? String {
                        let request = FriendRequest(id: id, username: username)
                        self.friendRequests.append(request)  // Add the new request to the list
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")  // Debug print
                self.showAlert(message: "Request failed: \(error.localizedDescription)")
            }
        }
    }


    func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}




struct RequestRow: View {
    var request: FriendRequest
    @Binding var acceptingRequest: String?
    var onResponse: (String, Bool) -> Void

    var body: some View {
        HStack {
            Text(request.username)
                .font(.headline)
                .padding(.leading, 15)

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




