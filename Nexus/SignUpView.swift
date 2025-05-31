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
                // Custom ana arka plan
                Color.clear.mainBackground()
                
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                        
                        Text("Join Nexus Today!")
                            .font(.titleMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        TextField("E-Mail", text: $email)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(25)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(25)
                            .textContentType(.newPassword)
                            .disableAutocorrection(true)
                            .padding(.horizontal)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(25)
                            .textContentType(.password)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        register()
                    }) {
                        Text("Sign Up")
                    }
                    .buttonStyle(MainButtonStyle())
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
