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
                .padding(.top, 5) // Slight top padding to ensure it’s not too close to the top edge

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
                .padding(.top, 0) // No extra space between image and button
            }

            // Features displayed before subscription (if not subscribed)
            if !isSubscribed {
                VStack(alignment: .center, spacing: 18) {
                    Text("Your VIP Pass to Productivity")
                        .font(.title2) // Slightly bigger title
                        .bold()
                        .padding(.bottom, 8)

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

                    // The 9th Feature at the Bottom, Centered
                    FeatureRow(icon: "sparkles", text: "Access every new feature")
                        .foregroundColor(.yellow)
                        .padding(.top, 18)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 25)
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
                    .font(.system(size: 20, weight: .bold)) // Bigger title
                    .foregroundColor(.primary)
            }
            Text(description)
                .font(.system(size: 18, weight: .medium)) // Slightly bigger text
                .foregroundColor(.primary)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - FeatureRow (For Grid)
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .font(.system(size: 20)) // Slightly bigger icon
            Text(text)
                .foregroundColor(.primary)
                .font(.system(size: 18)) // Slightly bigger text
        }
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

