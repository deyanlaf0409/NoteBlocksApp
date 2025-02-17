//
//  ProfileView.swift
//  NoteBlocks App
//
//  Created by Deyan on 10.02.25.
//

import SwiftUI

struct ProfileView: View {
    var username: String
    var onLogout: () -> Void = {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }
    @Binding var showLogoutConfirmation: Bool
    
    @State private var friends: [Friend] = [] // State to store the friends
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false  // To track loading state
    
    let userId = UserDefaults.standard.string(forKey: "userId")
    
    var body: some View {
        NavigationView {  // Wrap ProfileView with NavigationView
            VStack {
                Text("Welcome to \(username)'s Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Navigate to FriendsView with the fetched friends
                NavigationLink(destination: FriendsView(friends: friends)) {
                    Text("Friends")
                        .bold()
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.top, 16)
                
                // Log out button
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    Text("Log Out")
                        .bold()
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.top, 16)
                
                // Display loading spinner while fetching friends
                if isLoading {
                    ProgressView("")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                
                // Show error message if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .onAppear {
                fetchFriends()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out") {
                    onLogout()
                }
                .foregroundColor(.orange)
                
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    func fetchFriends() {
        guard let userId = userId, !userId.isEmpty else {
            self.errorMessage = "Error: No userId found in UserDefaults"
            return
        }
        
        self.isLoading = true
        
        let parameters = ["action": "list_friends", "user_id": userId]
        
        NetworkManager.shared.makeRequest(parameters: parameters) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let jsonResponse):
                    if let friendsData = jsonResponse["friends"] as? [[String: Any]] {
                        self.friends = friendsData.compactMap { data in
                            guard let id = data["id"] as? String,
                                  let username = data["username"] as? String else { return nil }
                            return Friend(id: id, username: username)
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to fetch friends: \(error.localizedDescription)"
                }
            }
        }
    }
}




