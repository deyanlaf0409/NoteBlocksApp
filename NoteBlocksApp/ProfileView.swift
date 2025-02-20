//
//  ProfileView.swift
//  NoteBlocks App
//
//  Created by Deyan on 10.02.25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ProfileView: View {
    var username: String
    var onLogout: () -> Void = {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }
    @Binding var showLogoutConfirmation: Bool
    
    @State private var friends: [Friend] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var qrCodeImage: UIImage? = nil

    let userId = UserDefaults.standard.string(forKey: "userId") ?? "" // Ensure no nil value
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(username)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                if let qrCodeImage = qrCodeImage {
                    ZStack {
                        // QR Code image
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)  // Size of the QR code
                            .clipShape(RoundedRectangle(cornerRadius: 22))  // Rounded corners for QR code
                            .shadow(radius: 10)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(30)
                        
                        // Circle with the image in the center
                        Image("qrimage")  // Replace with your image name or a UIImage reference
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)  // Size of the circle image
                            .clipShape(Circle())  // Clips the image to a circular shape
                            .overlay(Circle().stroke(Color.black, lineWidth: 4))  // Optional: Adds a white border around the circle
                    }
                } else {
                    Image(systemName: "qrcode")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.gray)
                }
                
                Spacer().frame(height: 50)

                
                HStack(spacing: 20) {
                    NavigationLink(destination: FriendsView(friends: friends)) {
                        Label("Friends", systemImage: "person.2.fill")
                            .bold()
                            .padding()
                            .frame(maxWidth: 150)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        Label("Log Out", systemImage: "arrow.right.circle.fill")
                            .bold()
                            .padding()
                            .frame(maxWidth: 150)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .padding(.top, 16)


                
                if isLoading {
                    //ProgressView()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .onAppear {
                fetchFriends()
                generateQRCodeLocally()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out") {
                    onLogout()
                }
                .foregroundColor(.orange)
                
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    func fetchFriends() {
        guard !userId.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No userId found."
            }
            return
        }
        
        self.isLoading = true
        
        let parameters = ["action": "list_friends", "user_id": userId]
        
        NetworkManager.shared.makeRequest(parameters: parameters) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let jsonResponse):
                    if let friendsData = jsonResponse["friends"] as? [[String: Any]] {
                        self.friends = friendsData.compactMap { data in
                            guard let id = data["id"] as? String,
                                  let username = data["username"] as? String else { return nil }
                            return Friend(id: id, username: username)
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to fetch friends: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func generateQRCodeLocally() {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(username.utf8) // Encode the username instead of user ID
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High Error Correction

        guard let outputImage = filter.outputImage else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create QR code"
            }
            return
        }

        let transform = CGAffineTransform(scaleX: 10, y: 10) // Scale QR code
        let scaledQR = outputImage.transformed(by: transform)

        let context = CIContext()
        if let cgImage = context.createCGImage(scaledQR, from: scaledQR.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.qrCodeImage = uiImage
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate QR code"
            }
        }
    }

}




