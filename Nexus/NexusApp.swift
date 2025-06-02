//
//  NexusApp.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI
import FirebaseCore

@main
struct NexusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
