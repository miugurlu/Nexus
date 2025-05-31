//
//  ButtonStyle+Custom.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.buttonYellow)
            .cornerRadius(25)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
} 
