//
//  PaymentPage.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 31.05.2025.
//

import SwiftUI

struct PaymentView: View {
    var body: some View {
        ZStack {
            Color.clear.mainBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Plan")
                            .font(.titleMedium)
                        Text("Premium (text)")
                            .font(.titleLarge)
                            .foregroundColor(.pYellow)
                    }
                    Divider()
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Plan")
                            .font(.titleMedium)
                        HStack(spacing: 16) {
                            Button("Free") { }
                                .buttonStyle(MainButtonStyle())
                            Button("Personal") { }
                                .buttonStyle(MainButtonStyle())
                            Button("Premium") { }
                                .buttonStyle(MainButtonStyle())
                        }
                    }
                    Divider()
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Methods")
                            .font(.titleMedium)
                        HStack {
                            Image(systemName: "creditcard")
                            Text("**** **** **** 1234 (text)")
                            Spacer()
                            Button("Edit") { }
                                .font(.caption)
                        }
                        Button("Add New Card") { }
                            .font(.caption)
                    }
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment History")
                            .font(.titleMedium)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    PaymentView()
}

