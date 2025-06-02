//
//  BackgroundModifier.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI

struct MainBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color("darkBackground1"), Color("darkBackground2")]
                    : [Color("lightBackground1"), Color("lightBackground2")],
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
