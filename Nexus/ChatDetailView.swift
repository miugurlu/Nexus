//
//  ChatDetailView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 7.06.2025.
//

import SwiftUI
import FirebaseAuth

struct MessageModel: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
}

class MessageViewModel: ObservableObject {
    @Published var messages: [FirebaseManager.MessageModel] = []
    let chatId: String
    let currentUserId: String
    let currentUserName: String
    init(chatId: String, currentUserId: String, currentUserName: String) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        fetchMessages()
    }
    func fetchMessages() {
        FirebaseManager.shared.fetchMessages(for: chatId) { [weak self] msgs in
            self?.messages = msgs
        }
    }
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        FirebaseManager.shared.sendMessage(to: chatId, senderId: currentUserId, senderName: currentUserName, text: text) { _ in }
    }
}

struct ChatDetailView: View {
    let chat: Chat
    let users: [FirebaseManager.UserModel]
    @State private var messageText: String = ""
    @StateObject private var viewModel: MessageViewModel
    
    init(chat: Chat, users: [FirebaseManager.UserModel]) {
        let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? "unknown"
        let userName = FirebaseAuth.Auth.auth().currentUser?.displayName ?? "Me"
        _viewModel = StateObject(wrappedValue: MessageViewModel(chatId: chat.id, currentUserId: userId, currentUserName: userName))
        self.chat = chat
        self.users = users
    }
    
    var otherUserName: String {
        guard let currentUserId = FirebaseAuth.Auth.auth().currentUser?.uid else { return "" }
        let otherId = chat.participants.first(where: { $0 != currentUserId }) ?? ""
        return users.first(where: { $0.id == otherId })?.name ?? "Chat"
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        HStack {
                            if msg.senderId == viewModel.currentUserId {
                                Spacer()
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                            } else {
                                Text(msg.text)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                }.padding()
            }
            HStack {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    if !messageText.isEmpty {
                        viewModel.sendMessage(messageText)
                        messageText = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
    }
} 
