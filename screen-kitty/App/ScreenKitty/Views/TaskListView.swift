import SwiftUI
import KittyKit

struct TaskListView: View {
    @EnvironmentObject private var controller: KittyController

    @State private var newTitle = ""
    @State private var hasDueDate = false
    @State private var newDue = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            List {
                addTaskSection

                Section("open") {
                    let open = controller.state.tasks.filter { !$0.isCompleted }
                        .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
                    if open.isEmpty {
                        Text("nothing open. suspicious, but okay")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(open) { task in
                        TaskRowView(task: task) {
                            controller.completeTask(task.id)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            controller.deleteTask(open[index].id)
                        }
                    }
                }

                let completed = controller.state.tasks.filter { $0.isCompleted }
                    .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
                if !completed.isEmpty {
                    Section("done") {
                        ForEach(completed.prefix(15)) { task in
                            HStack {
                                Text(task.title)
                                    .strikethrough()
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let at = task.completedAt {
                                    Text(at, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions {
                                Button("redo") {
                                    controller.uncompleteTask(task.id)
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
        }
    }

    private var addTaskSection: some View {
        Section("new task") {
            TextField("what needs doing?", text: $newTitle)
                .onSubmit(addTask)

            Toggle("set a due time", isOn: $hasDueDate.animation())
            if hasDueDate {
                DatePicker("due", selection: $newDue)
            }
            Button {
                addTask()
            } label: {
                Label("add", systemImage: "plus.circle.fill")
            }
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addTask() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        controller.addTask(title: trimmed, due: hasDueDate ? newDue : nil)
        newTitle = ""
        hasDueDate = false
    }
}
