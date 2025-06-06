//
//  ProfileView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 1.06.2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var showPasswordChange: Bool = false
    @State private var pushNotifications: Bool = true
    @State private var emailNotifications: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var showLogoutAlert: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.clear.mainBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Profil Bilgileri
                    SectionHeader("Profile Information")
                    VStack(spacing: 16) {
                        HStack {
                            Text("Name:").bold()
                            Text(displayName)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Text("E-Mail:").bold()
                            Text(email)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack{
                            Button("Change Password") {
                                showPasswordChange = true
                            }
                            .buttonStyle(SmallButtonStyle())
                            .sheet(isPresented: $showPasswordChange) {
                                PasswordChangeView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    // Bildirim Ayarları
                    SectionHeader("Notification Settings")
                    VStack(spacing: 8) {
                        Toggle("Push Notifications", isOn: $pushNotifications).bold().tint(.pYellow)
                        Toggle("E-Mail Notifications", isOn: $emailNotifications).bold().tint(.pYellow)
                    }
                    Divider()
                    // Tema Seçimi
                    SectionHeader("Application Theme")
                    HStack{
                        Text("Theme Selection").bold()
                        Spacer()
                        Picker("Theme", selection: $isDarkMode) {
                            Image(systemName: "sun.max.fill").tag(false)
                            Image(systemName: "moon.fill").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }
                    
                    Divider()
                    
                    // Çıkış Yap Butonu
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.pYellow)
                        .cornerRadius(10)
                    }
                }
                .foregroundColor(.pYellow)
                .padding()
                .onAppear {
                    if let user = Auth.auth().currentUser {
                        print("Kullanıcı: \(user)")
                        displayName = user.displayName ?? "No Name"
                        email = user.email ?? "No Email"
                    }
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            // Ana sayfaya dön
            dismiss()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.pYellow)
            .padding(.bottom, 2)
    }
}

struct PasswordChangeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("New Password (Again)", text: $confirmPassword)
                }
                
                Section {
                    Button(action: changePassword) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Change Password")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match"
            showError = true
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "New password must be at least 6 characters long"
            showError = true
            return
        }
        
        isLoading = true
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "User not found"
            showError = true
            isLoading = false
            return
        }
        
        // Önce mevcut şifre ile yeniden giriş yaparak doğrulama
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
                return
            }
            
            // Şifreyi güncelle
            user.updatePassword(to: newPassword) { error in
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else {
                    // Başarılı şifre değişikliği
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
