//
//  Explore.swift
//  NoteBlocks App
//
//  Created by Deyan on 22.02.25.
//

import SwiftUI

struct GuestLoginPromptView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Top title
            Text("Ready to Jump in the Fun part ?")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 20)

            // Image
            Image("explore") // Replace with your actual asset name
                .resizable()
                .scaledToFit()
                .frame(width: 335, height: 335)
                .opacity(0.9)

            // Large Title
            Text("Create your Account Now to Start the Party! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Cancel Button
            Button("Back") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: 150)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.black]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)

            Spacer()
        }
        .padding()
    }
}

