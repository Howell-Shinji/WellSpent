import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @State private var isHovered = false
    @FocusState private var editFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: TokyoNightTheme.spacingM) {
            CompletionToggle(checked: todo.completed, action: onToggle)

            if isEditing {
                TextField(
                    "",
                    text: $draft,
                    prompt: Text("待办内容").foregroundColor(TokyoNightTheme.textMuted)
                )
                    .textFieldStyle(.plain)
                    .font(TokyoNightTheme.body())
                    .foregroundColor(TokyoNightTheme.textPrimary)
                    .tint(TokyoNightTheme.accent)
                    .accessibilityLabel("编辑待办")
                    .focused($editFocused)
                    .onSubmit {
                        commit()
                    }
                    .onExitCommand {
                        cancel()
                    }
                    .onAppear {
                        editFocused = true
                    }
            } else {
                Text(todo.text)
                    .font(todo.completed ? TokyoNightTheme.body() : TokyoNightTheme.bodyStrong())
                    .foregroundColor(
                        todo.completed
                            ? TokyoNightTheme.textMuted
                            : TokyoNightTheme.textPrimary
                    )
                    .strikethrough(todo.completed, color: TokyoNightTheme.textMuted)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        beginEditing()
                    }
                    .accessibilityAction(named: "编辑") {
                        beginEditing()
                    }
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(isHovered ? TokyoNightTheme.danger : TokyoNightTheme.textMuted)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                            .fill(isHovered ? TokyoNightTheme.danger.opacity(0.10) : Color.clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("删除")
            .accessibilityLabel("删除 \(todo.text)")
        }
        .padding(.horizontal, TokyoNightTheme.spacingM)
        .padding(.vertical, TokyoNightTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: TokyoNightTheme.radiusM, style: .continuous)
                .fill(TokyoNightTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TokyoNightTheme.radiusM, style: .continuous)
                .stroke(
                    isEditing || isHovered
                        ? TokyoNightTheme.accent.opacity(isEditing ? 0.85 : 0.46)
                        : TokyoNightTheme.border.opacity(0.72),
                    lineWidth: TokyoNightTheme.hairline
                )
        )
        .onHover { isHovered = $0 }
    }

    private func commit() {
        onUpdate(draft)
        isEditing = false
    }

    private func beginEditing() {
        draft = todo.text
        isEditing = true
    }

    private func cancel() {
        draft = todo.text
        isEditing = false
    }
}
