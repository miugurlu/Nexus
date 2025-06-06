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

struct FilesView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isShowingFilePicker = false
    @State private var selectedFile: FirebaseManager.UserFile?
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isUploading = false

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
                            }) {
                                HStack {
                                    Image(systemName: "doc.richtext")
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
                allowedContentTypes: [.pdf],
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
            .sheet(item: $selectedFile, onDismiss: {
                selectedFile = nil
            }) { file in
                PDFPreviewView(url: file.url)
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

struct PDFPreviewView: View {
    let url: URL
    @State private var pdfData: Data?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Downloading...")
            } else if let error = error {
                Text("Could not open PDF: \(error)")
                    .foregroundColor(.red)
            } else if let pdfData = pdfData, let document = PDFDocument(data: pdfData) {
                PDFKitView(document: document)
            } else {
                Text("Could not open PDF (unknown error)")
                    .foregroundColor(.red)
            }
        }
        .onAppear { startLoading() }
        .onChange(of: url) { _ in startLoading() }
    }

    private func startLoading() {
        pdfData = nil
        isLoading = true
        error = nil
        downloadPDF()
    }

    private func downloadPDF() {
        let task = URLSession.shared.dataTask(with: url) { data, response, err in
            DispatchQueue.main.async {
                if let err = err {
                    self.error = err.localizedDescription
                    self.isLoading = false
                } else if let data = data {
                    self.pdfData = data
                    self.isLoading = false
                } else {
                    self.error = "Unknown error"
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

#Preview {
    FilesView()
}
