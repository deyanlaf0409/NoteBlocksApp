//
//  Send.swift
//  NoteBlocksApp
//
//  Created by Deyan on 19.03.25.
//

import SwiftUI

struct FriendsList: View {
    @Environment(\.presentationMode) var presentationMode
    
    var friends: [Friend]
    var note: Note // Pass the note to send
    
    @State private var isSending = false
    
    @EnvironmentObject var noteStore: NoteStore
    
    @State private var selectedFriends: Set<String> = []
    @State private var searchText: String = ""
    
    
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                if friends.isEmpty {
                    Spacer() // Push content up
                    Image("mailbox") // Image should render here
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .opacity(0.9)
                        .padding(.top, 1)
                    
                    Text("You don't have any friends")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search friends...", text: $searchText)
                            .foregroundColor(.primary)
                            .padding(5)
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    
                    List(filteredFriends) { friend in
                                                HStack {
                                                    Image(systemName: "person.fill")
                                                    Text(friend.username)
                                                    Spacer()
                                                    
                                                    if selectedFriends.contains(friend.id) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    toggleSelection(for: friend)
                                                }
                                            }
                                            .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Friends")
            
            // Circular send button at the bottom
            VStack {
                Spacer()
                
                Button(action: {
                    handleSendNote()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("paperplane")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // Adjust icon size
                        .padding(20) // Button size
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle()) // Make it circular
                        .shadow(radius: 5)
                }
                .padding(.bottom, 40) // Ensure proper spacing
            }
        }
    }
    
    private func toggleSelection(for friend: Friend) {
        if selectedFriends.contains(friend.id) {
            selectedFriends.remove(friend.id)
        } else {
            selectedFriends.insert(friend.id)
        }
    }
    
    private func handleSendNote() {
        isSending = true
        for friendId in selectedFriends {
            noteStore.sendNoteOnServer(note: note, userId: friendId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success: break
                        // Handle success (e.g., show a confirmation message)
                    case .failure(_): break
                        // Handle error (e.g., show an error message)
                    }
                    isSending = false
                }
            }
        }
    }
}


