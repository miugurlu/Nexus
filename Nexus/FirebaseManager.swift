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

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var uploadedFiles: [FileItem] = []
    @Published var files: [UserFile] = []
    
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
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
} 
