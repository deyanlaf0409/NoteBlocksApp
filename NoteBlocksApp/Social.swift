//
//  Social.swift
//  NoteBlocks App
//
//  Created by Deyan on 11.02.25.
//

import SwiftUI


struct FriendRequest: Identifiable {
    var id: String
    var username: String
}

struct SocialView: View {
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0
    @State private var pendingRequestsCount: Int = 0 // Track pending requests
    @State private var friendRequests: [FriendRequest] = [] // List of friend requests
    
    @State private var alertMessage: String = "" // Alert message
    @State private var showAlert: Bool = false // Alert visibility

    var body: some View {
        VStack {
            Picker("Options", selection: $selectedTab) {
                Text("Search").tag(0)
                Text(pendingRequestsCount > 0 ? "Requests (\(pendingRequestsCount))" : "Requests").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                FriendSearchView()
            } else {
                FriendRequestsView(friendRequests: $friendRequests, onUpdate: fetchNetworkData)
            }
            
            Spacer()
        }
        .navigationTitle("Network")
        .onAppear {
            fetchNetworkData() // Fetch both request count and friend requests when the screen appears
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Fetches both the number of pending friend requests and the list of friend requests
    func fetchNetworkData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

        let url = URL(string: "http://192.168.0.222/project/API/network.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postData = "action=count_requests&user_id=\(userId)"
        request.httpBody = postData.data(using: .utf8)

        // Fetch the request count first
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let count = jsonResponse["count"] as? Int {
                        DispatchQueue.main.async {
                            self.pendingRequestsCount = count
                        }
                    }
                } catch {
                    print("Failed to parse JSON for request count")
                }
            }
        }.resume()

        // Now fetch the friend requests
        let requestData = "action=list_requests&user_id=\(userId)"
        request.httpBody = requestData.data(using: .utf8)

        // Fetch the list of requests
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let requests = jsonResponse["pending_requests"] as? [[String: Any]] {

                        DispatchQueue.main.async {
                            self.friendRequests = requests.compactMap {
                                if let id = $0["id"] as? String, let username = $0["username"] as? String {
                                    return FriendRequest(id: id, username: username)
                                }
                                return nil
                            }
                        }
                    }
                } catch {
                    print("Failed to parse JSON for friend requests")
                }
            }
        }.resume()
    }
}


struct FriendRequestsView: View {
    @Binding var friendRequests: [FriendRequest] // Binding to the friend requests
    var onUpdate: () -> Void // Callback function to update request count
    
    @State private var alertMessage: String = "" // Alert message
    @State private var showAlert: Bool = false // Alert visibility
    @State private var acceptingRequest: String? = nil // Track the request currently being accepted

    var body: some View {
        VStack {
            if friendRequests.isEmpty {
                Text("No pending friend requests")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // List of friend requests
                ForEach(friendRequests) { request in
                    HStack {
                        // Left side: the username text, slightly indented
                        Text(request.username)
                            .font(.headline)
                            .padding(.leading, 15) // Indent the username a bit to the right
                        
                        Spacer() // This pushes the "Accept" and "Decline" buttons to the right

                        // Right side: Accept and Decline buttons, slightly adjusted to the left
                        HStack(spacing: 15) {
                            Button(action: {
                                print("Accept button tapped for \(request.username)")
                                respondToRequest(requestId: request.id, accept: true)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                            .disabled(acceptingRequest != nil && acceptingRequest != request.id) // Disable if another request is being processed
                            
                            Button(action: {
                                print("Decline button tapped for \(request.username)")
                                respondToRequest(requestId: request.id, accept: false)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .disabled(acceptingRequest != nil && acceptingRequest != request.id) // Disable if another request is being processed
                        }
                        .padding(.trailing, 15) // Adjust buttons to the left
                    }
                    .padding(.vertical, 5) // Add padding to ensure buttons are spaced properly
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Request Response"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func respondToRequest(requestId: String, accept: Bool) {
        // Prevent multiple button presses for the same request
        acceptingRequest = requestId
        
        let action = accept ? "accept_request" : "decline_request"
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let url = URL(string: "http://192.168.0.222/project/API/network.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let postData = "action=\(action)&user_id=\(userId)&target_username=\(requestId)"
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessage = "Request failed: \(error.localizedDescription)"
                    self.showAlert = true
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertMessage = "No response from server"
                    self.showAlert = true
                }
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["message"] as? String {
                    DispatchQueue.main.async {
                        self.alertMessage = message
                        self.showAlert = true
                        onUpdate() // Refresh requests and count after responding
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Invalid response from server"
                        self.showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Error parsing response"
                    self.showAlert = true
                }
            }
        }.resume()
        
        // Reset the accepting request state after the request is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.acceptingRequest = nil
        }
    }
}













struct FriendSearchView: View {
    @State private var searchText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Text("Send friendship request")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)

            HStack {
                TextField("Enter username", text: $searchText)
                    .foregroundColor(.primary)
                    .padding(5)
                    .frame(height: 40)
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
                .padding(.trailing, 10)
                .disabled(searchText.isEmpty)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func sendFriendRequest(username: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            alertMessage = "User not authenticated"
            showAlert = true
            return
        }

        let url = URL(string: "http://192.168.0.222/project/API/network.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postData = "action=send_request&user_id=\(userId)&target_username=\(username)"
        request.httpBody = postData.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Request failed: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "No response from server"
                    showAlert = true
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["message"] as? String {
                    DispatchQueue.main.async {
                        alertMessage = message
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Invalid response from server"
                    showAlert = true
                }
            }
        }.resume()
    }
}




struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        SocialView()
    }
}



