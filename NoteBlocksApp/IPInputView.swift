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
            Text("Discover More")
                .font(.headline)
                .padding()

            // Conditional button (Start Subscription OR Sign In)
            if isSubscribed {
                // Sign In Button (Shown AFTER subscription)
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
                // Start Subscription Button (Shown BEFORE subscription)
                Button("Let's Go") {
                    startSubscription()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 12)  // slightly larger padding for better touch area
                .padding(.horizontal, 20) // wider horizontal padding
                .frame(maxWidth: 240)    // slightly wider button
                .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))  // gradient background
                .foregroundColor(.white)
                .cornerRadius(25)  // smoother rounded corners
                .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 4)  // subtle shadow for depth
            }

            if !isSubscribed {
                VStack(alignment: .leading, spacing: 15) { // Increased spacing
                    Text("Why Go Premium?")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)

                    featureRow(icon: "icloud.and.arrow.up", text: "Unlimited cloud storage")
                    featureRow(icon: "arrow.triangle.2.circlepath", text: "24/7 Synchronization and backup")
                    featureRow(icon: "message", text: "Priority support")
                    featureRow(icon: "desktopcomputer", text: "Accessible from any device")
                    featureRow(icon: "nosign", text: "No ads or interruptions")
                    featureRow(icon: "paperplane", text: "Fast send to friends or team members")
                    //featureRow(icon: "person.3", text: "Join a community full of people")
                    featureRow(icon: "sparkles", text: "Access to every new feature")
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

    // Helper function for feature rows
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) { // Added spacing between icon and text
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 22)) // Increased icon size
            Text(text)
                .font(.system(size: 18, weight: .medium)) // Increased text size
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

