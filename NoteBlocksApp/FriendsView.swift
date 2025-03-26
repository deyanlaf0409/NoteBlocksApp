//
//  FriendsView.swift
//  NoteBlocks App
//
//  Created by Deyan on 17.02.25.
//

import SwiftUI

struct Friend: Identifiable, Decodable {
    let id: String
    let username: String
}


struct FriendsView: View {
    @State var friends: [Friend]  // Accept friends array passed from ProfileView
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var friendToRemove: Friend? = nil
    @State private var showRemoveConfirmation: Bool = false
    @State private var noFriendsMessage: String? = nil  // To show the "No friends" message

    let userId = UserDefaults.standard.string(forKey: "userId")
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // If there are no friends, show a message
            if friends.isEmpty {
                Image("friends") // Image should render here
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .opacity(0.9)
                    .padding(.top, 1)
                
                Text("You don't have any friends")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(friends) { friend in
                    HStack {
                        Image(systemName: "person.fill")
                        Text(friend.username)
                        
                        Spacer()
                        
                        // Remove button next to each friend
                        Button(action: {
                            friendToRemove = friend
                            showRemoveConfirmation = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(5)
                        }
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .confirmationDialog(
            "Are you sure you want to remove this friend?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Friend") {
                if let friend = friendToRemove {
                    removeFriend(friend: friend)
                }
            }
            .foregroundColor(.orange)
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // Function to remove the friend using the API
    func removeFriend(friend: Friend) {
        guard let userId = userId else {
            self.errorMessage = "No user ID found"
            return
        }
        
        self.isLoading = true
        
        let parameters = [
            "action": "remove_friend",
            "user_id": userId,
            "target_username": friend.username
        ]
        
        // Network request to remove friend
        NetworkManager.shared.makeRequest(parameters: parameters) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let jsonResponse):
                    if let status = jsonResponse["status"] as? String, status == "success" {
                        // Successfully removed the friend
                        self.errorMessage = nil
                        
                        // Remove the friend from the list locally
                        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
                            friends.remove(at: index)
                        }
                        
                        // Check if the list is empty and update the UI
                        if friends.isEmpty {
                            noFriendsMessage = "You don't have any friends"
                        } else {
                            noFriendsMessage = nil
                        }
                    } else {
                        self.errorMessage = jsonResponse["message"] as? String
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to remove friend: \(error.localizedDescription)"
                }
            }
        }
    }
}




