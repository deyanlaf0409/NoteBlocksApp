//
//  Social.swift
//  NoteBlocks App
//
//  Created by Deyan on 11.02.25.
//

import SwiftUI

struct SocialView: View {
    var body: some View {
        VStack {
            
            Text("This is where the feed of shared blocks would go.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Network")
    }
}
