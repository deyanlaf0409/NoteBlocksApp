import SwiftUI
import StoreKit
import SafariServices

struct IPInputView: View {
    @State private var showSafariView = false
    @State private var isSubscribed = false

    // Hardcoded IP address
    let hardcodedIPAddress = "192.168.0.222" // Replace with your actual IP

    var body: some View {
        VStack {
            // Title before subscription, Disclaimer after
            Text(isSubscribed ? "⚠️  Important Disclaimer" : "Unlock a World Without Limits!")
                .font(.headline)
                .padding()

            // Show rules only after subscribing
            if isSubscribed {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 22)) // Larger icon size
                        Text("Protect Your Privacy")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Never share personal data, passwords, or your home address.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)

                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 22))
                        Text("Follow the Rules")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Respect the guidelines and help keep our community safe and welcoming for everyone.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)
                    
                    HStack {
                        Image(systemName: "person.2.wave.2.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 22))
                        Text("Here for You")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("If anything feels off, contact our support team—we’re happy to help!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }


            // Conditional button (Start Subscription OR Sign In)
            if isSubscribed {
                Button("Sign In") {
                    checkSubscriptionStatus()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: 200)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(15)

            } else {
                Button("🎉 Let's Go ! 🥳") {
                    startSubscription()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .frame(maxWidth: 240)
                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 4)
            }

            // Show subscription benefits before subscribing
            if !isSubscribed {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Your VIP Pass to Productivity")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)

                    FeatureRow(icon: "paperplane", text: "Fast send to all your friends and team members", iconColor: .primary)
                    FeatureRow(icon: "globe", text: "Access to the NoteBlocks Network", iconColor: .primary)
                    FeatureRow(icon: "nosign", text: "No ads or interruptions", iconColor: .primary)
                    FeatureRow(icon: "desktopcomputer", text: "Accessible from any device", iconColor: .primary)
                    FeatureRow(icon: "icloud.and.arrow.up", text: "Unlimited cloud storage", iconColor: .primary)
                    FeatureRow(icon: "arrow.triangle.2.circlepath", text: "24/7 Synchronization and backup", iconColor: .primary)
                    FeatureRow(icon: "message", text: "Priority support", iconColor: .primary)
                    FeatureRow(icon: "sparkles", text: "Access to every new feature", iconColor: .yellow)
                }
                .padding(.horizontal)
                .padding(.top, 25)
            }

            Spacer()
        }
        .padding()
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

    // Function to check subscription status
    private func checkSubscriptionStatus() {
        if isSubscribed {
            showSafariView = true
        }
    }

    // Function to initiate subscription process
    private func startSubscription() {
        isSubscribed = true
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title)
            Text(text)
                .foregroundColor(.primary)
        }
    }
}

