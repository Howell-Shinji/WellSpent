import SwiftUI

struct TodoRow: View {
    @EnvironmentObject var store: TodoStore
    let todo: Todo
    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var fullTextHeight: CGFloat = 0
    @State private var visibleTextHeight: CGFloat = 0
    @FocusState private var editFocused: Bool

    private var isEditing: Bool { store.editingID == todo.id }
    private var textFont: Font { todo.completed ? Theme.body() : Theme.bodyStrong() }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                CompletionToggle(checked: todo.completed) { store.toggle(todo.id) }
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    if isEditing {
                        TextField("待办内容", text: $store.editDraft, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(Theme.body())
                            .foregroundColor(Theme.textPrimary)
                            .tint(Theme.accent)
                            .lineLimit(1...8)
                            .focused($editFocused)
                            .accessibilityLabel("编辑待办")
                            .onSubmit { store.commitEditing(ifMatching: todo.id) }
                            .onExitCommand { store.cancelEditing(todo.id) }
                            .onAppear { editFocused = true }
                    } else {
                        Text(todo.text)
                            .font(textFont)
                            .foregroundColor(todo.completed ? Theme.textMuted : Theme.textPrimary)
                            .strikethrough(todo.completed, color: Theme.textMuted)
                            .lineLimit(isExpanded ? nil : 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear { visibleTextHeight = proxy.size.height }
                                        .onChange(of: proxy.size.height) { visibleTextHeight = $0 }
                                }
                            }
                            .overlay(alignment: .topLeading) {
                                Text(todo.text)
                                    .font(textFont)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background {
                                        GeometryReader { proxy in
                                            Color.clear
                                                .onAppear { fullTextHeight = proxy.size.height }
                                                .onChange(of: proxy.size.height) { fullTextHeight = $0 }
                                        }
                                    }
                                    .hidden()
                                    .accessibilityHidden(true)
                                    .allowsHitTesting(false)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { store.beginEditing(todo.id) }
                            .onTapGesture {
                                if store.editingID != todo.id { store.commitEditing() }
                            }
                            .accessibilityAction(named: "编辑") { store.beginEditing(todo.id) }

                        if isExpanded || fullTextHeight > visibleTextHeight + 1 {
                            Button(isExpanded ? "收起" : "展开全文") {
                                store.commitEditing()
                                isExpanded.toggle()
                            }
                            .buttonStyle(.plain)
                            .font(Theme.small())
                            .foregroundColor(Theme.accent)
                        }
                    }
                }
                .padding(.top, 3)

                Menu {
                    ForEach(TodoPriority.allCases, id: \.self) { priority in
                        Button {
                            store.setPriority(priority, for: todo.id)
                        } label: {
                            Label(priority.title,
                                  systemImage: todo.priority == priority ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: todo.priority == .high ? "flag.fill" : "flag")
                        if todo.priority != .normal {
                            Text(todo.priority.shortTitle)
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(todo.priority == .high ? Theme.priorityHigh : Theme.textMuted)
                    .frame(width: 38, height: 28)
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .tint(todo.priority == .high ? Theme.priorityHigh : Theme.textMuted)
                .help("优先级：\(todo.priority.title)")
                .accessibilityLabel("设置\(todo.text)的优先级，当前\(todo.priority.title)")

                Button { store.delete(todo.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(isHovered ? Theme.danger : Theme.textMuted)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("删除，可撤销")
                .accessibilityLabel("删除 \(todo.text)")
            }

            if isEditing {
                HStack {
                    Text("空内容会保留原任务")
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                    Button("取消") { store.cancelEditing(todo.id) }
                    Button("保存") { store.commitEditing(ifMatching: todo.id) }
                }
                .buttonStyle(.plain)
                .font(Theme.small())
                .foregroundColor(Theme.accent)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(RoundedRectangle(cornerRadius: Theme.radiusM).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusM)
                .stroke(isEditing || isHovered ? Theme.accent.opacity(isEditing ? 0.85 : 0.46)
                        : Theme.border.opacity(0.72), lineWidth: Theme.hairline)
        )
        .onHover { isHovered = $0 }
        .onChange(of: editFocused) { focused in
            if !focused {
                DispatchQueue.main.async { store.commitEditing(ifMatching: todo.id) }
            }
        }
        .onDisappear { store.commitEditing(ifMatching: todo.id) }
    }
}
