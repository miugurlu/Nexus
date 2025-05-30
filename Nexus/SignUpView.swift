//
//  Colors.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 30.05.2025.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isRegistered = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(stops: [
                    .init(color: .yellow2, location: 0.30),
                    .init(color: .white, location: 0.70),
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Join Nexus Today!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        TextField("E-Mail", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .textContentType(.newPassword)
                            .disableAutocorrection(true)
                            .padding(.horizontal)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .textContentType(.password)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        register()
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brown1)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if isRegistered {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .navigationBarBackButtonHidden(false)
        }
    }
    
    func register() {
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match!"
            showAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Successfully registered user!"
                isRegistered = true
                showAlert = true
            }
        }
    }
}

#Preview {
    SignUpView()
} 
