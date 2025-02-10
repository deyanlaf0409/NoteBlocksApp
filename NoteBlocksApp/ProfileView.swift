//
//  ProfileView.swift
//  NoteBlocks App
//
//  Created by Deyan on 10.02.25.
//
import SwiftUI

struct ProfileView: View {
    var username: String
    
    var body: some View {
        VStack {
            Text("Welcome to \(username)'s Profile")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Add other profile-related content here
            // For example:
            // Text("Age: 25")
            // Text("Location: New York")
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
