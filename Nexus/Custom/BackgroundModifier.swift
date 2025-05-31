//
//  BackgroundModifier.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI

struct MainBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [.backgroundPrimary, .backgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
    }
}

extension View {
    func mainBackground() -> some View {
        self.modifier(MainBackground())
    }
} 
