//
//  MainChatView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 7.06.2025.
//

import SwiftUI
import FirebaseAuth

struct Chat: Identifiable, Codable {
    let id: String
    let participants: [String]
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let isTyping: Bool
}

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    func fetchChats() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        FirebaseManager.shared.fetchChats(for: currentUserId) { [weak self] chats in
            self?.chats = chats.map {
                Chat(id: $0.id, participants: $0.participants, lastMessage: $0.lastMessage, time: $0.time, unreadCount: $0.unreadCount, isTyping: $0.isTyping)
            }
        }
    }
}

struct MainChatView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var showUserSheet = false
    @State private var users: [FirebaseManager.UserModel] = []
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color.clear.mainBackground()
                List(viewModel.chats) { chat in
                    NavigationLink(destination: ChatDetailView(chat: chat, users: users)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(chatDisplayName(for: chat)).font(.headline)
                                Text(chat.isTyping ? "typing..." : chat.lastMessage)
                                    .font(.subheadline)
                                    .foregroundColor(chat.isTyping ? .green : .gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(chat.time).font(.caption)
                                if chat.unreadCount > 0 {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text("\(chat.unreadCount)")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showUserSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .background(Color.clear)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .mainBackground()
        .onAppear {
            viewModel.fetchChats()
            let currentUserId = Auth.auth().currentUser?.uid
            FirebaseManager.shared.fetchUsers { fetchedUsers in
                users = fetchedUsers.filter { $0.id != currentUserId }
            }
        }
        .sheet(isPresented: $showUserSheet) {
            NavigationView {
                List(users) { user in
                    Button(action: {
                        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
                        FirebaseManager.shared.addChat(name: user.name, participantIds: [currentUserId, user.id]) { _ in
                            showUserSheet = false
                            viewModel.fetchChats()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(user.name).font(.headline)
                            Text(user.email).font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("Kişi Seç")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") { showUserSheet = false }
                    }
                }
            }
        }
    }
    
    // Karşıdaki kullanıcının adını bul
    func chatDisplayName(for chat: Chat) -> String {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return "" }
        let otherId = chat.participants.first(where: { $0 != currentUserId }) ?? ""
        return users.first(where: { $0.id == otherId })?.name ?? "Chat"
    }
}

// Chat modeline participants eklenmeli ve yardımcı fonksiyon eklenmeli
struct ChatWithParticipants: Identifiable, Codable {
    let id: String
    let participants: [String]
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let isTyping: Bool
    
    func otherParticipantId(currentUserId: String) -> String? {
        participants.first(where: { $0 != currentUserId })
    }
}

#Preview {
    MainChatView()
}
