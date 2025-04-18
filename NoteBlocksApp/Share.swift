//
//  Share.swift
//  NoteBlocksApp
//
//  Created by Deyan on 1.04.25.
//

import SwiftUI

struct ShareNoteModal: View {
    @Binding var note: Note
    @Binding var showModal: Bool

    var body: some View {
        VStack {
            Button(action: {
                toggleSharedStatus()
            }) {
                Text(note.shared ? "Unshare" : "Share")
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
            }
            .padding()

            Button("Close") {
                showModal = false
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
        }
        .padding()
    }

    func toggleSharedStatus() {
        note.shared.toggle()
        toggleSharedAPI(noteId: note.id)
    }

    func toggleSharedAPI(noteId: UUID) {
        let url = URL(string: "https://noteblocks.net/API/share.php")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["noteId": noteId.uuidString]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling shared status: \(error.localizedDescription)")
                return
            }

            if let data = data,
               let response = try? JSONDecoder().decode([String: Bool].self, from: data) {
                DispatchQueue.main.async {
                    if let sharedStatus = response["shared"] {
                        note.shared = sharedStatus
                    }
                }
            }
        }
        
        task.resume()
    }
}

