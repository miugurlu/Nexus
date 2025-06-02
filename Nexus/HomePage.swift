//
//  HomePage.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 31.05.2025.
//

import SwiftUI

enum MenuOption: String, CaseIterable, Identifiable {
    case home = "Home"
    case profile = "Profile"
    case payment = "Payment"
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .home: return "house"
        case .profile: return "person"
        case .payment: return "creditcard"
        }
    }
}

struct SideMenu: View {
    @Binding var selected: MenuOption
    @Binding var showMenu: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(MenuOption.allCases) { option in
                Button(action: {
                    selected = option
                    withAnimation {
                        showMenu = false
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: option.icon)
                            .frame(width: 24)
                        Text(option.rawValue)
                            .font(.titleMedium)
                    }
                    .foregroundColor(selected == option ? .textSecondary : .textPrimary)
                }
            }
            Spacer()
        }
        .padding(.top, 100)
        .padding(.horizontal, 24)
        .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
        .background(Color.clear.mainBackground())
        .ignoresSafeArea()
    }
}

struct HomePage: View {
    @State private var showMenu = false
    @State private var selected: MenuOption = .home

    var body: some View {
        ZStack {
            // Main Content
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        withAnimation {
                            showMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 28, height: 22)
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 56)
                
                Group {
                    switch selected {
                    case .home:
                        Text("Welcome to Home Page!")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .padding()
                        
                    case .profile:
                        VStack(alignment: .leading) {
                            Text("Profile")
                                .font(.titleLarge)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)
                            ProfilePage()
                                .padding(.top, 0)
                        }
                        
                    case .payment:
                        VStack(alignment: .leading) {
                            Text("Payment")
                                .font(.titleLarge)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)
                            PaymentPage()
                                .padding(.top, 0)
                        }
                    }
                }
                Spacer()
            }
            .mainBackground()
            .disabled(showMenu)
            .blur(radius: showMenu ? 3 : 0)
            
            // Side Menu
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showMenu = false
                        }
                    }
                HStack {
                    SideMenu(selected: $selected, showMenu: $showMenu)
                        .transition(.move(edge: .leading))
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomePage()
}
