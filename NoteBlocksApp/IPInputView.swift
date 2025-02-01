import SwiftUI
import StoreKit
import SafariServices

struct IPInputView: View {
    @Binding var ipAddress: String
    @State private var showSafariView = false
    @State private var isSubscribed = false
    @State private var showSubscriptionPrompt = false

    var body: some View {
        VStack {
            Text("Enter Server IP Address")
                .font(.headline)
                .padding()

            TextField("IPv4 Address", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Log In Button
            Button("Log In") {
                if !ipAddress.isEmpty {
                    checkSubscriptionStatus()
                }
            }
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
            .disabled(!isSubscribed) // Disable the Log In button if not subscribed

            if !isSubscribed {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Why Go Premium?")
                        .font(.title2) // Increased font size
                        .bold()
                        .padding(.bottom, 5)

                    Text("• Unlimited cloud storage")
                    Text("• 24/7 Priority support")
                    Text("• Join a community full of people")
                    Text("• Access to awesome new features")

                    // Centering the "Start Subscription" button
                    HStack {
                        Spacer()
                        Button("Start Subscription") {
                            startSubscription()
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: 150)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                .padding(.top, 20) // Add some space between Log In button and this section
            }

            Spacer()
        }
        .padding()
        .onAppear {
            checkSubscriptionStatus()
        }
        .onChange(of: isSubscribed) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "isSubscribed")
            if newValue {
                ipAddress = ""
            }
        }
        .sheet(isPresented: $showSafariView) {
            if let url = URL(string: "http://\(ipAddress)/project/Login/construct.php?AppRequest=true") {
                SafariView(url: url)
            }
        }
    }

    // Function to check subscription status
    private func checkSubscriptionStatus() {
            if isSubscribed {
                showSafariView = true
            } else {
                showSubscriptionPrompt = true
            }
        }

    // Function to initiate subscription process
    private func startSubscription() {
            isSubscribed = true
        }
    }


