//
//  PaymentView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 31.05.2025.
//

import SwiftUI

enum Plan: String, CaseIterable {
    case free = "Free"
    case personal = "Personal"
    case premium = "Premium"
}

struct PaymentView: View {
    @State private var selectedPlan: Plan = .premium
    var body: some View {
        ZStack {
            Color.clear.mainBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Plan")
                            .font(.titleMedium)
                        Text(selectedPlan.rawValue)
                            .font(.titleLarge)
                            .foregroundColor(.pYellow)
                    }
                    Divider()
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Plan")
                            .font(.titleMedium)
                        HStack(spacing: 16) {
                            ForEach(Plan.allCases, id: \.self) { plan in
                                Button(plan.rawValue) {
                                    selectedPlan = plan
                                }
                                .buttonStyle(MainButtonStyle())
                            }
                        }
                    }
                    Divider()
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Methods (not working)")
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

