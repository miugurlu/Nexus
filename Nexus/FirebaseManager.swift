//
//  FirebaseManager.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 28.05.2025.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var uploadedFiles: [FileItem] = []
    @Published var files: [UserFile] = []
    @Published var notes: [Note] = []
    @Published var reminders: [Reminder] = []
    
    struct FileItem: Identifiable {
        let id: String
        let name: String
        let url: String
        let uploadDate: Date
        let userId: String
    }
    
    struct UserFile: Identifiable {
        let id: String
        let name: String
        let url: URL
        let userId: String
    }
    
    struct Note: Identifiable, Codable {
        let id: String
        let title: String
        let content: String
        let createdAt: Date
        let userId: String
    }
    
    struct Reminder: Identifiable, Codable {
        let id: String
        let title: String
        let description: String
        let date: Date
        let repeatOption: RepeatOption
        var isCompleted: Bool
        let userId: String
        
        enum RepeatOption: String, Codable, CaseIterable, Identifiable {
            case none, daily, weekly, monthly
            var id: String { self.rawValue }
            var displayName: String {
                switch self {
                case .none: return "None"
                case .daily: return "Daily"
                case .weekly: return "Weekly"
                case .monthly: return "Monthly"
                }
            }
        }
    }
    
    struct ChatModel: Identifiable, Codable {
        let id: String
        let participants: [String]
        let lastMessage: String
        let time: String
        let unreadCount: Int
        let isTyping: Bool
    }
    
    struct MessageModel: Identifiable, Codable {
        let id: String
        let senderId: String
        let senderName: String
        let text: String
        let timestamp: Date
    }
    
    struct UserModel: Identifiable, Codable {
        let id: String
        let name: String
        let email: String
    }
    
    func uploadFile(data: Data, fileName: String, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child("files/\(userId)/\(fileName)")
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL alınamadı"])))
                    return
                }
                
                let fileData: [String: Any] = [
                    "name": fileName,
                    "url": downloadURL.absoluteString,
                    "uploadDate": Date(),
                    "userId": userId
                ]
                
                self.db.collection("files").addDocument(data: fileData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(downloadURL.absoluteString))
                    }
                }
            }
        }
    }
    
    func fetchUserFiles(userId: String) {
        db.collection("files")
            .whereField("userId", isEqualTo: userId)
            .order(by: "uploadDate", descending: true)
            .addSnapshotListener { snapshot, error in
                var newFiles: [UserFile] = []
                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        if let name = data["name"] as? String,
                           let urlString = data["url"] as? String,
                           let url = URL(string: urlString),
                           let userId = data["userId"] as? String {
                            newFiles.append(UserFile(id: doc.documentID, name: name, url: url, userId: userId))
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.files = newFiles
                }
            }
    }
    
    func deleteFile(fileId: String, completion: @escaping (Error?) -> Void) {
        db.collection("files").document(fileId).delete { error in
            completion(error)
        }
    }
    
    // PDF yükle ve Firestore'a kaydet
    func uploadPDF(data: Data, fileName: String, userId: String, completion: @escaping (Error?) -> Void) {
        let ref = storage.reference().child("pdfs/\(userId)/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(error)
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(error)
                } else if let url = url {
                    self.db.collection("files").addDocument(data: [
                        "name": fileName,
                        "url": url.absoluteString,
                        "uploadDate": Timestamp(date: Date()),
                        "userId": userId
                    ]) { error in
                        completion(error)
                    }
                }
            }
        }
    }
    
    // Firestore ve Storage'dan dosya sil
    func deleteFile(_ file: UserFile, completion: @escaping (Error?) -> Void) {
        // Storage'dan sil
        let storageRef = storage.reference(forURL: file.url.absoluteString)
        storageRef.delete { error in
            if let error = error {
                completion(error)
                return
            }
            // Firestore'dan sil
            self.db.collection("files").document(file.id).delete(completion: completion)
        }
    }
    
    func addNote(title: String, content: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let note = Note(
            id: UUID().uuidString,
            title: title,
            content: content,
            createdAt: Date(),
            userId: userId
        )
        
        try await db.collection("notes").document(note.id).setData([
            "id": note.id,
            "title": note.title,
            "content": note.content,
            "createdAt": note.createdAt,
            "userId": note.userId
        ])
        
        await MainActor.run {
            notes.append(note)
        }
    }
    
    func fetchNotes() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let snapshot = try await db.collection("notes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let fetchedNotes = snapshot.documents.compactMap { document -> Note? in
            let data = document.data()
            guard let id = data["id"] as? String,
                  let title = data["title"] as? String,
                  let content = data["content"] as? String,
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
                  let userId = data["userId"] as? String else {
                return nil
            }
            
            return Note(id: id, title: title, content: content, createdAt: createdAt, userId: userId)
        }
        
        await MainActor.run {
            self.notes = fetchedNotes
        }
    }
    
    func deleteNote(_ note: Note) async throws {
        try await db.collection("notes").document(note.id).delete()
        
        await MainActor.run {
            notes.removeAll { $0.id == note.id }
        }
    }
    
    func addReminder(title: String, description: String, date: Date, repeatOption: Reminder.RepeatOption) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]) }
        let reminder = Reminder(
            id: UUID().uuidString,
            title: title,
            description: description,
            date: date,
            repeatOption: repeatOption,
            isCompleted: false,
            userId: userId
        )
        try await db.collection("reminders").document(reminder.id).setData([
            "id": reminder.id,
            "title": reminder.title,
            "description": reminder.description,
            "date": reminder.date,
            "repeatOption": reminder.repeatOption.rawValue,
            "isCompleted": reminder.isCompleted,
            "userId": reminder.userId
        ])
        await MainActor.run {
            self.reminders.append(reminder)
        }
    }

    func fetchReminders() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]) }
        let snapshot = try await db.collection("reminders")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date")
            .getDocuments()
        let fetched = snapshot.documents.compactMap { doc -> Reminder? in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let title = data["title"] as? String,
                  let description = data["description"] as? String,
                  let date = (data["date"] as? Timestamp)?.dateValue(),
                  let repeatRaw = data["repeatOption"] as? String,
                  let repeatOption = Reminder.RepeatOption(rawValue: repeatRaw),
                  let isCompleted = data["isCompleted"] as? Bool,
                  let userId = data["userId"] as? String else { return nil }
            return Reminder(id: id, title: title, description: description, date: date, repeatOption: repeatOption, isCompleted: isCompleted, userId: userId)
        }
        await MainActor.run {
            self.reminders = fetched
        }
    }

    func deleteReminder(_ reminder: Reminder) async throws {
        try await db.collection("reminders").document(reminder.id).delete()
        await MainActor.run {
            self.reminders.removeAll { $0.id == reminder.id }
        }
    }

    func toggleReminderCompleted(_ reminder: Reminder) async throws {
        let newValue = !reminder.isCompleted
        try await db.collection("reminders").document(reminder.id).updateData(["isCompleted": newValue])
        await MainActor.run {
            if let idx = self.reminders.firstIndex(where: { $0.id == reminder.id }) {
                self.reminders[idx].isCompleted = newValue
            }
        }
    }

    func fetchChats(for userId: String, completion: @escaping ([ChatModel]) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "time", descending: true)
            .addSnapshotListener { snapshot, error in
                var chats: [ChatModel] = []
                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        if let id = doc.documentID as String?,
                           let participants = data["participants"] as? [String],
                           let lastMessage = data["lastMessage"] as? String,
                           let time = data["time"] as? String,
                           let unreadCount = data["unreadCount"] as? Int,
                           let isTyping = data["isTyping"] as? Bool {
                            chats.append(ChatModel(id: id, participants: participants, lastMessage: lastMessage, time: time, unreadCount: unreadCount, isTyping: isTyping))
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion(chats)
                }
            }
    }

    func addChat(name: String, participantIds: [String], completion: ((Error?) -> Void)? = nil) {
        let chatData: [String: Any] = [
            "name": name,
            "participants": participantIds,
            "lastMessage": "",
            "time": "",
            "unreadCount": 0,
            "isTyping": false
        ]
        db.collection("chats").addDocument(data: chatData) { error in
            completion?(error)
        }
    }

    func fetchMessages(for chatId: String, completion: @escaping ([MessageModel]) -> Void) {
        db.collection("chats").document(chatId).collection("messages").order(by: "timestamp").addSnapshotListener { snapshot, error in
            var messages: [MessageModel] = []
            if let documents = snapshot?.documents {
                for doc in documents {
                    let data = doc.data()
                    if let id = doc.documentID as String?,
                       let senderId = data["senderId"] as? String,
                       let senderName = data["senderName"] as? String,
                       let text = data["text"] as? String,
                       let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() {
                        messages.append(MessageModel(id: id, senderId: senderId, senderName: senderName, text: text, timestamp: timestamp))
                    }
                }
            }
            DispatchQueue.main.async {
                completion(messages)
            }
        }
    }

    func sendMessage(to chatId: String, senderId: String, senderName: String, text: String, completion: ((Error?) -> Void)? = nil) {
        let messageData: [String: Any] = [
            "senderId": senderId,
            "senderName": senderName,
            "text": text,
            "timestamp": Date()
        ]
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData) { error in
            completion?(error)
        }
    }

    func fetchUsers(completion: @escaping ([UserModel]) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            var users: [UserModel] = []
            if let documents = snapshot?.documents {
                for doc in documents {
                    let data = doc.data()
                    if let id = doc.documentID as String?,
                       let name = data["name"] as? String,
                       let email = data["email"] as? String {
                        users.append(UserModel(id: id, name: name, email: email))
                    }
                }
            }
            DispatchQueue.main.async {
                completion(users)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
} 
