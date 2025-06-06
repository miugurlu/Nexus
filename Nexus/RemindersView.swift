//
//  RemindersView.swift
//  Nexus
//
//  Created by İbrahim Uğurlu on 6.06.2025.
//

import SwiftUI

// Enum for filter
enum ReminderFilter: String, CaseIterable, Identifiable {
    case active, completed
    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
}

struct RemindersView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isShowingNewReminderSheet = false
    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var newDate = Date()
    @State private var newRepeat: FirebaseManager.Reminder.RepeatOption = .none
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isAddingReminder = false
    @State private var filter: ReminderFilter = .active

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Picker("", selection: $filter) {
                        ForEach(ReminderFilter.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.top, .horizontal])

                    if isAddingReminder {
                        ProgressView("Adding reminder...")
                            .padding()
                    }

                    let reminders = firebaseManager.reminders.filter { filter == .completed ? $0.isCompleted : !$0.isCompleted }
                    if reminders.isEmpty && !isAddingReminder {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: filter == .completed ? "checkmark.circle" : "bell")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.3))
                            Text(filter == .completed ? "No completed reminders." : "No active reminders.")
                                .foregroundColor(.gray)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List {
                            ForEach(reminders) { reminder in
                                ReminderCard(reminder: reminder, onToggle: {
                                    Task {
                                        do {
                                            try await firebaseManager.toggleReminderCompleted(reminder)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            isShowingError = true
                                        }
                                    }
                                }, onDelete: {
                                    Task {
                                        do {
                                            try await firebaseManager.deleteReminder(reminder)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            isShowingError = true
                                        }
                                    }
                                })
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                // Floating Action Button
                Button(action: { isShowingNewReminderSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("Add Reminder")
            }
            .sheet(isPresented: $isShowingNewReminderSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Reminder Details")) {
                            TextField("Title", text: $newTitle)
                            TextField("Description", text: $newDescription)
                            DatePicker("Date & Time", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                            Picker("Repeat", selection: $newRepeat) {
                                ForEach(FirebaseManager.Reminder.RepeatOption.allCases) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                        }
                    }
                    .navigationTitle("New Reminder")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isShowingNewReminderSheet = false
                        },
                        trailing: Button("Save") {
                            Task {
                                await saveReminder()
                            }
                        }
                        .disabled(newTitle.isEmpty)
                    )
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("Okay", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .mainBackground()
        }
        .onAppear {
            Task {
                do {
                    try await firebaseManager.fetchReminders()
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }

    private func saveReminder() async {
        isAddingReminder = true
        do {
            try await firebaseManager.addReminder(title: newTitle, description: newDescription, date: newDate, repeatOption: newRepeat)
            newTitle = ""
            newDescription = ""
            newDate = Date()
            newRepeat = .none
            isShowingNewReminderSheet = false
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
        isAddingReminder = false
    }
}

struct ReminderCard: View {
    let reminder: FirebaseManager.Reminder
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reminder.title)
                        .font(.headline)
                    if reminder.repeatOption != .none {
                        Text(reminder.repeatOption.displayName)
                            .font(.caption)
                            .padding(4)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                if !reminder.description.isEmpty {
                    Text(reminder.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                Text(reminder.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(reminder.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RemindersView()
} 
