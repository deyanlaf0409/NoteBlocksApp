import SwiftUI
import StoreKit
import SafariServices

struct IPInputView: View {
    @State private var showSafariView = false
    @State private var isSubscribed = false

    let hardcodedIPAddress = "192.168.0.222"

    var body: some View {
        VStack(spacing: 0) {  // Set spacing to 0 to ensure no space between elements
            // Title at the top with reduced padding
            Text(isSubscribed ? "⚠️  Important Disclaimer" : "Unlock a World Without Limits!")
                .font(.title2)
                .padding(.top, 7) // Slight top padding to ensure it’s not too close to the top edge

            if isSubscribed {
                // Show the disclaimer content if subscribed
                DisclaimerView()
                    .padding(.top, 20) // Adjust padding as needed
            } else {
                // Show the initial subscription flow
                if !isSubscribed {
                    Image("subscribe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300) // Explicit width and height, adjust as needed
                        .clipped() // To make sure it doesn't stretch
                        .opacity(0.9)
                }

                // The button placed immediately after the image with no space
                if !isSubscribed {
                    Button("🎉 Let's Go ! 🥳") {
                        startSubscription()
                    }
                    .styledPrimaryButton()
                    .padding(.top, 10) // No extra space between image and button
                }

                // Features displayed before subscription (if not subscribed)
                if !isSubscribed {
                    VStack(alignment: .center, spacing: 18) {
                        Text("Your VIP Pass to Productivity")
                            .font(.title2) // Slightly bigger title
                            .bold()
                            .padding(.bottom, 8)
                            .padding(.top, 0)

                        // Grouped Features in a Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            FeatureRow(icon: "paperplane", text: "Fast send to friends")
                            FeatureRow(icon: "person.3", text: "Join the NoteBlocks community")
                            FeatureRow(icon: "nosign", text: "No ads or interruptions")
                            FeatureRow(icon: "desktopcomputer", text: "Access on any device")
                            FeatureRow(icon: "checkmark.icloud.fill", text: "Unlimited cloud storage")
                            FeatureRow(icon: "infinity", text: "Unlimited accounts")
                            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "24/7 Sync & Backup")
                            FeatureRow(icon: "message", text: "Priority support")
                        }
                        .padding(.horizontal)
                        .padding(.top, 3)

                        // The 9th Feature at the Bottom, Centered
                        // Center only the last feature row
                        HStack {
                            Spacer() // Pushes content to center
                            FeatureRow(icon: "sparkles", text: "Access every new feature", isSpecial: true)
                            Spacer() // Pushes content to center
                        }
                        .frame(maxWidth: .infinity) // Ensures full width usage
                        .padding(.top, 10)

                    }
                    .padding(.top, 25)
                }
            }

            // The button that should be present after the subscription, for example, "Sign In" or "Proceed"
            if isSubscribed {
                Button("Proceed") {
                    // Handle your action for proceeding to the dashboard or login
                    showSafariView = true
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 12)
                .padding(.horizontal, 22)
                .frame(maxWidth: 240)
                .background(.black)
                .foregroundColor(.white)
                .cornerRadius(24)
                .padding(.top, 18)
            }

            Spacer()
        }
        .padding([.leading, .trailing], 0) // Remove horizontal padding from the parent VStack
        .onAppear {
            checkSubscriptionStatus()
        }
        .onChange(of: isSubscribed) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "isSubscribed")
        }
        .sheet(isPresented: $showSafariView) {
            if let url = URL(string: "http://\(hardcodedIPAddress)/project/Login/construct.php?AppRequest=true") {
                SafariView(url: url)
            }
        }
    }

    private func checkSubscriptionStatus() {
        if isSubscribed {
            showSafariView = true
        }
    }

    private func startSubscription() {
        isSubscribed = true
    }
}


// MARK: - Disclaimer View
struct DisclaimerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclaimerItem(icon: "exclamationmark.shield.fill", title: "Protect Your Privacy", description: "Never share personal data or passwords.")
            DisclaimerItem(icon: "checkmark.shield.fill", title: "Follow the Rules", description: "Respect the guidelines and keep it safe for everyone.")
            DisclaimerItem(icon: "person.2.wave.2.fill", title: "Here for You", description: "If anything feels off, contact our support team!")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        
        Image("disclaimer") // Replace with your custom image name if needed
                        .resizable()
                        .scaledToFit()
                        .frame(width: 275, height: 275) // Adjust image size here
                        .padding(.top, 0) // Optional space between text and image
    }
}

struct DisclaimerItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .font(.system(size: 22)) // Slightly bigger icon
                Text(title)
                    .font(.system(size: 24, weight: .bold)) // Bigger title
                    .foregroundColor(.primary)
                    .padding(.top, 10)
            }
            Text(description)
                .font(.system(size: 18, weight: .regular)) // Slightly bigger text
                .foregroundColor(.primary)
                .padding(.bottom, 10)

        }
    }
}

// MARK: - FeatureRow (For Grid)
struct FeatureRow: View {
    let icon: String
    let text: String
    var isSpecial: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if !isSpecial {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .font(.system(size: 22))
                    .frame(width: 30, alignment: .leading)

                Text(text)
                    .foregroundColor(.primary)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer() // Push to center
                HStack(spacing: 8) { // Group icon & text together
                    Image(systemName: icon)
                        .foregroundColor(.yellow)
                        .font(.system(size: 22))
                    Text(text)
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                }
                Spacer() // Push to center
            }
        }
        .padding(.leading, isSpecial ? 0 : 20) // Move normal rows slightly right
    }
}



// MARK: - Button Styles
extension View {
    func styledButton() -> some View {
        self
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: 200)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    func styledPrimaryButton() -> some View {
        self
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .frame(maxWidth: 240)
            .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundColor(.white)
            .cornerRadius(24)
            .shadow(color: Color.red.opacity(0.5), radius: 9, x: 0, y: 3)
    }
}

