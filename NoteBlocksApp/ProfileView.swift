//
//  ProfileView.swift
//  NoteBlocks App
//
//  Created by Deyan on 10.02.25.
//
import SwiftUI

struct ProfileView: View {
    var username: String
    var onLogout: () -> Void
    @Binding var showLogoutConfirmation: Bool // Add binding for showing the confirmation
    
    var body: some View {
        VStack {
            Text("Welcome to \(username)'s Profile")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Log Out Button
            Button(action: {
                showLogoutConfirmation = true  // Show the confirmation alert
            }) {
                Text("Log Out")
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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showLogoutConfirmation) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    onLogout()  // Perform log out action
                },
                secondaryButton: .cancel()
            )
        }
    }
}


