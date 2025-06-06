//
//  NotesView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 6.06.2025.
//

import SwiftUI
import FirebaseFirestore

struct NotesView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isShowingNewNoteSheet = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isAddingNote = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                
                Color.clear.mainBackground()

                VStack {
                    if isAddingNote {
                        ProgressView("Adding note...")
                            .padding()
                    }
                    if firebaseManager.notes.isEmpty && !isAddingNote {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "note.text")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("You haven't added any notes yet.")
                                .foregroundColor(.gray)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(firebaseManager.notes) { note in
                                    NoteCard(note: note, onDelete: {
                                        Task {
                                            do {
                                                try await firebaseManager.deleteNote(note)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                isShowingError = true
                                            }
                                        }
                                    })
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isShowingNewNoteSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                        }
                        .accessibilityLabel("Add Note")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewNoteSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Note Details")) {
                            TextField("Title", text: $newNoteTitle)
                            TextEditor(text: $newNoteContent)
                                .frame(height: 200)
                        }
                    }
                    .navigationTitle("New Note")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isShowingNewNoteSheet = false
                        },
                        trailing: Button("Save") {
                            Task {
                                await saveNote()
                            }
                        }
                        .disabled(newNoteTitle.isEmpty || newNoteContent.isEmpty)
                    )
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("Okay", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                do {
                    try await firebaseManager.fetchNotes()
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }
    
    private func saveNote() async {
        isAddingNote = true
        do {
            try await firebaseManager.addNote(title: newNoteTitle, content: newNoteContent)
            newNoteTitle = ""
            newNoteContent = ""
            isShowingNewNoteSheet = false
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
        isAddingNote = false
    }
}

struct NoteCard: View {
    let note: FirebaseManager.Note
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            Text(note.content)
                .font(.body)
                .foregroundColor(.primary)
            HStack {
                Spacer()
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    NotesView()
} 
