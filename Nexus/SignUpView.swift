//
//  SignuUp.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 30.05.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isRegistered = false
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {

                Color.clear.mainBackground()
                
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.titleLarge)
                            .foregroundColor(.pYellow)
                        
                        Text("Join Nexus Today!")
                            .font(.titleMedium)
                            .foregroundColor(.pYellow)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        TextField("", text: $name, prompt:Text("Name").foregroundColor(.placeholderGrey))
                            .padding()
                            .background(.white)
                            .cornerRadius(25)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .padding(.horizontal)
                        TextField("", text: $email, prompt:Text("E-Mail").foregroundColor(.placeholderGrey))
                            .padding()
                            .background(.white)
                            .cornerRadius(25)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password, prompt:Text("Password").foregroundColor(.placeholderGrey))
                            .padding()
                            .background(.white)
                            .cornerRadius(25)
                            .textContentType(.newPassword)
                            .disableAutocorrection(true)
                            .padding(.horizontal)
                        
                        SecureField("Confirm Password", text: $confirmPassword, prompt:Text("Confirm Password").foregroundColor(.placeholderGrey))
                            .padding()
                            .background(.white)
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
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please write a name."
            showAlert = true
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = result?.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    let db = Firestore.firestore()
                    let userData: [String: Any] = [
                        "name": name,
                        "email": email
                    ]
                    db.collection("users").document(user.uid).setData(userData) { _ in }
                    alertMessage = "Successfully registered user!"
                    isRegistered = true
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    SignUpView()
} 
