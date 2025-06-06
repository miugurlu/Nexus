//
//  FilesView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import FirebaseAuth
import QuickLook

struct FilesView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isShowingFilePicker = false
    @State private var selectedFile: FirebaseManager.UserFile?
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isUploading = false
    @State private var previewURL: URL?
    @State private var isLoadingPreview = false
    @State private var retryCount = 0
    private let maxRetries = 3

    var body: some View {
        NavigationView {
            VStack {
                Button(action: { isShowingFilePicker = true }) {
                    Label("Add Files", systemImage: "plus")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pYellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top)
                if isUploading {
                    ProgressView("Downloading...")
                        .padding()
                }
                if firebaseManager.files.isEmpty && !isUploading {
                    Spacer()
                    Text("You haven't uploaded any files yet.")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(firebaseManager.files) { file in
                            Button(action: {
                                selectedFile = file
                                retryCount = 0
                                downloadAndPreview(file: file)
                            }) {
                                HStack {
                                    Image(systemName: fileIcon(for: file.name))
                                        .foregroundColor(.blue)
                                    Text(file.name)
                                        .font(.body)
                                }
                            }
                        }
                        .onDelete(perform: deleteFiles)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [
                    .pdf,
                    .plainText,
                    UTType(filenameExtension: "docx")!,
                    UTType(filenameExtension: "doc")!,
                    UTType(filenameExtension: "xlsx")!,
                    UTType(filenameExtension: "xls")!
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    uploadFile(url: url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
            .sheet(item: $selectedFile) { file in
                ZStack {
                    if isLoadingPreview {
                        ProgressView("Loading preview...")
                    } else if let url = previewURL {
                        QuickLookPreview(url: url)
                    } else {
                        VStack(spacing: 16) {
                            Text("Could not load preview")
                                .foregroundColor(.red)
                            if retryCount < maxRetries {
                                Button("Retry") {
                                    downloadAndPreview(file: file)
                                }
                                .buttonStyle(MainButtonStyle())
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("Okay", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            if let user = Auth.auth().currentUser {
                firebaseManager.fetchUserFiles(userId: user.uid)
            }
        }
    }

    private func fileIcon(for fileName: String) -> String {
        let fileExtension = fileName.lowercased().split(separator: ".").last ?? ""
        switch fileExtension {
        case "pdf": return "doc.richtext"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "txt": return "doc.text"
        default: return "doc"
        }
    }

    private func downloadAndPreview(file: FirebaseManager.UserFile) {
        isLoadingPreview = true
        previewURL = nil

        // Create a URLRequest with timeout and cache policy (no Accept header)
        var request = URLRequest(url: file.url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoadingPreview = false

                if let httpResponse = response as? HTTPURLResponse {
                    print("STATUS CODE: \(httpResponse.statusCode)")
                    print("CONTENT-TYPE: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "")")
                }
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("RESPONSE STRING: \(responseString)")
                }

                if let error = error {
                    if retryCount < maxRetries {
                        retryCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            downloadAndPreview(file: file)
                        }
                        return
                    }
                    errorMessage = "Failed to load file: \(error.localizedDescription)"
                    isShowingError = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    if retryCount < maxRetries {
                        retryCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            downloadAndPreview(file: file)
                        }
                        return
                    }
                    errorMessage = "Server error occurred"
                    isShowingError = true
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received"
                    isShowingError = true
                    return
                }

                do {
                    let tempDir = FileManager.default.temporaryDirectory
                    let tempFile = tempDir.appendingPathComponent(file.name)
                    try data.write(to: tempFile)
                    previewURL = tempFile
                    retryCount = 0
                } catch {
                    errorMessage = "Failed to save file: \(error.localizedDescription)"
                    isShowingError = true
                }
            }
        }
        task.resume()
    }

    private func uploadFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            isUploading = true
            if let user = Auth.auth().currentUser {
                firebaseManager.uploadPDF(data: data, fileName: url.lastPathComponent, userId: user.uid) { error in
                    isUploading = false
                    if let error = error {
                        errorMessage = error.localizedDescription
                        isShowingError = true
                    }
                }
            } else {
                isUploading = false
                errorMessage = "User session not found."
                isShowingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            let file = firebaseManager.files[index]
            firebaseManager.deleteFile(file) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
            super.init()
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

#Preview {
    FilesView()
}
