//
//  IntroView.swift
//  Late-Night Notes
//
//  Created by Deyan on 5.10.24.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct IntroView: View {
    @Binding var loggedInUser: String?
    @Binding var showNotes: Bool
    @Binding var showSafari: Bool

    @State private var ipAddress: String = "" // Default IP
    private var loginUrlString: String {
        "http://\(ipAddress)/project/Login/construct.php?AppRequest=true"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to the NoteBlocks Official App")
                    .font(.largeTitle)
                    .padding()

                TextField("Enter Server IP Address", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.URL) // Suggest a keyboard suitable for entering URLs or IPs

                Button(action: {
                    showSafari = true
                    print(loginUrlString)
                }) {
                    Text("Log In")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.vertical, 8)
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

                Button(action: {
                    // Set guest mode in UserDefaults
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(nil, forKey: "loggedInUser")

                    showNotes = true // Move to ContentView
                }) {
                    Text("Continue as Guest")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.vertical, 8)
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

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showNotes) {
                ContentView(showSafari: $showSafari, username: loggedInUser ?? "Guest", onLogout: {})
            }
            .sheet(isPresented: $showSafari, onDismiss: {
                // Reset the login state when the sheet is dismissed (if necessary)
                // Optionally, you can clear the username if the user didn't log in
            }) {
                if let url = URL(string: loginUrlString) {
                    SafariView(url: url)
                }
            }
        }
    }
}

