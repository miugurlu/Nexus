//
//  ContentView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to Nexus!")
                .font(.title)
                .padding()
            
            Text("You are now logged in")
                .foregroundColor(.secondary)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContentView()
}
