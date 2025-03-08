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
    @State private var showIPInputModal: Bool = false
    @State private var showNoConnectionAlert = false

    @ObservedObject var networkMonitor = NetworkMonitor() // Use your existing NetworkMonitor
    @Environment(\.colorScheme) var colorScheme  // Detect light/dark mode

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // App Logo (changes based on light/dark mode)
                Image(colorScheme == .dark ? "whitelogo" : "blacklogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                // App Header
                Text("Welcome to NoteBlocks")
                    .font(.system(size: 26))
                    .padding(.top, 1)
                    .padding(.bottom, 1)


                
                Image("index")  // Replace with your image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 275, height: 275)
                    .cornerRadius(10)
                    .padding(.top, 1)
                    

                // Log In Button
                Button(action: {
                    if networkMonitor.isConnected {
                        showIPInputModal = true
                    } else {
                        showNoConnectionAlert = true
                    }
                }) {
                    Text("Log In")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .padding(.top, 3)
                                                .frame(maxWidth: 150)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .cornerRadius(15)
                }
                .sheet(isPresented: $showIPInputModal) {
                    IPInputView()
                }

                // Continue as Guest Button
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(nil, forKey: "loggedInUser")

                    showNotes = true
                }) {
                    Text("Continue as Guest")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .frame(maxWidth: 150)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .cornerRadius(15)
                }

                Spacer()
                
                // Bottom Text
                bottomTextWithIcon
            }
            .padding()
            .navigationDestination(isPresented: $showNotes) {
                ContentView(username: loggedInUser ?? "Guest", onLogout: {})
            }
            .alert(isPresented: $showNoConnectionAlert) {
                Alert(title: Text("No Internet Connection"),
                      message: Text("Please check your internet connection and try again."),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var bottomTextWithIcon: some View {
        HStack {
            Text("© 2025 NoteBlocks")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 10)
    }
    
    
    
}

