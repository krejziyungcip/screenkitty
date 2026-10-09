import SwiftUI
import KittyKit

struct TaskRowView: View {
    let task: KittyTask
    var onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(Theme.accent(for: MoodTier(score: 70)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                if let due = task.due {
                    Text(dueLabel(due))
                        .font(.caption)
                        .foregroundStyle(task.isOverdue() ? .red : .secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func dueLabel(_ due: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: due, relativeTo: Date())
        return task.isOverdue() ? "overdue \(relative)" : "due \(relative)"
    }
}
