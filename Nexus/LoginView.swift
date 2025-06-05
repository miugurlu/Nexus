//
//  LoginView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.mainBackground()
                
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Nexus")
                            .font(.titleLarge)
                            .foregroundColor(.pYellow)
                        
                        Text("Welcome Back!")
                            .font(.titleMedium)
                            .foregroundColor(.pYellow)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        TextField("", text: $email, prompt:Text("E-Mail").foregroundColor(.placeholderGrey))
                        
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("", text: $password, prompt:Text("Password").foregroundColor(.placeholderGrey))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .textContentType(.password)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Sign Up")
                    }
                    .buttonStyle(MainButtonStyle())
                    .padding(.horizontal)
                    
                    Button(action: {
                        login()
                    }) {
                        Text("Log In")
                    }
                    .buttonStyle(MainButtonStyle())
                    .padding(.horizontal)
                    
                    Button("Forgot Password?") {
                    }
                    .foregroundColor(.pYellow)
                    .bold()
                    
                    Spacer()
                }
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                HomeView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                isLoggedIn = true
            }
        }
    }
}

#Preview {
    LoginView()
}
