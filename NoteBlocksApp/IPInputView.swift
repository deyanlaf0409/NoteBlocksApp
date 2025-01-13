import SwiftUI
import SafariServices

struct IPInputView: View {
    @Binding var ipAddress: String
    @State private var showSafariView = false
    
    var body: some View {
        VStack {
            Text("Enter Server IP Address")
                .font(.headline)
                .padding()

            TextField("IPv4 Address", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Log In") {
                if !ipAddress.isEmpty {
                    // Show the Safari view after the "Log In" button is tapped with a valid IP
                    showSafariView = true
                    print("IP Address entered: \(ipAddress)")
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

            Spacer()
        }
        .padding()
        .onAppear {
            // Reset the IP address and showSafari to ensure it's clean when the view appears
            ipAddress = ""
        }
        .sheet(isPresented: $showSafariView) {
            // Show Safari view when the button is pressed
            if let url = URL(string: "http://\(ipAddress)/project/Login/construct.php?AppRequest=true") {
                SafariView(url: url)
            }
        }
    }
}

