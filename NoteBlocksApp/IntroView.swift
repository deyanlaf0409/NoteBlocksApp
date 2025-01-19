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

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to NoteBlocks")
                    .font(.largeTitle)
                    .padding()

                Button(action: {
                    showIPInputModal = true
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
                .sheet(isPresented: $showIPInputModal) {
                    IPInputView(ipAddress: $ipAddress)
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
                ContentView(showSafari: .constant(false), username: loggedInUser ?? "Guest", onLogout: {})
            }
        }
    }
}

