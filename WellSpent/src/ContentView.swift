import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newTodoText = ""
    @State private var showSettings = false

    var body: some View {
        ZStack {
            TokyoNightTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, TokyoNightTheme.spacingL)
                    .padding(.top, TokyoNightTheme.spacingL)
                    .padding(.bottom, TokyoNightTheme.spacingM)

                ThemeDivider()

                inputBar
                    .padding(.horizontal, TokyoNightTheme.spacingL)
                    .padding(.vertical, TokyoNightTheme.spacingM)

                todoList

                ThemeDivider()

                footer
                    .padding(.horizontal, TokyoNightTheme.spacingL)
                    .padding(.vertical, TokyoNightTheme.spacingM)

                if showSettings {
                    ThemeDivider()
                    settingsPanel
                        .padding(TokyoNightTheme.spacingL)
                        .background(TokyoNightTheme.chrome.opacity(0.56))
                }
            }
        }
        .tint(TokyoNightTheme.accent)
        .overlay(
            RoundedRectangle(cornerRadius: TokyoNightTheme.radiusL, style: .continuous)
                .stroke(TokyoNightTheme.border.opacity(0.65), lineWidth: TokyoNightTheme.hairline)
        )
    }

    private var header: some View {
        HStack(spacing: TokyoNightTheme.spacingM) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WellSpent")
                    .font(TokyoNightTheme.title())
                    .foregroundColor(TokyoNightTheme.textPrimary)

                Text(headerSubtitle)
                    .font(TokyoNightTheme.small())
                    .foregroundColor(TokyoNightTheme.textMuted)
            }

            Spacer(minLength: TokyoNightTheme.spacingS)

            Text("\(store.undoneCount)/\(store.items.count)")
                .font(TokyoNightTheme.counter())
                .foregroundColor(TokyoNightTheme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(TokyoNightTheme.surface)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(TokyoNightTheme.border.opacity(0.72), lineWidth: 1)
                )
                .accessibilityLabel("\(store.undoneCount) 项未完成，共 \(store.items.count) 项")

            Button(action: { showSettings.toggle() }) {
                Image(systemName: showSettings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(showSettings ? TokyoNightTheme.accent : TokyoNightTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                            .fill(showSettings ? TokyoNightTheme.accentSoft.opacity(0.55) : TokyoNightTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                            .stroke(
                                showSettings
                                    ? TokyoNightTheme.accent.opacity(0.65)
                                    : TokyoNightTheme.border.opacity(0.72),
                                lineWidth: 1
                            )
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(showSettings ? "收起设置" : "打开设置")
            .accessibilityLabel(showSettings ? "收起设置" : "打开设置")
        }
    }

    private var inputBar: some View {
        HStack(spacing: TokyoNightTheme.spacingS) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(TokyoNightTheme.accent)
                .frame(width: 22, height: 22)

            TextField(
                "",
                text: $newTodoText,
                prompt: Text("写下一件要做的事…").foregroundColor(TokyoNightTheme.textMuted)
            )
            .textFieldStyle(.plain)
            .font(TokyoNightTheme.body())
            .foregroundColor(TokyoNightTheme.textPrimary)
            .tint(TokyoNightTheme.accent)
            .accessibilityLabel("新待办")
            .onSubmit {
                addTodo()
            }

            Button(action: addTodo) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(TokyoNightTheme.onAccent)
                    .frame(width: 29, height: 29)
                    .background(
                        RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                            .fill(TokyoNightTheme.accent)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canAddTodo)
            .opacity(canAddTodo ? 1 : 0.42)
            .help("添加待办（Enter）")
            .accessibilityLabel("添加待办")
        }
        .padding(.leading, TokyoNightTheme.spacingS)
        .padding(.trailing, TokyoNightTheme.spacingXS)
        .padding(.vertical, TokyoNightTheme.spacingXS)
        .background(
            RoundedRectangle(cornerRadius: TokyoNightTheme.radiusM, style: .continuous)
                .fill(TokyoNightTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TokyoNightTheme.radiusM, style: .continuous)
                .stroke(TokyoNightTheme.border.opacity(0.82), lineWidth: 1)
        )
    }

    private var todoList: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: TokyoNightTheme.spacingS) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(TokyoNightTheme.accent)
                        .padding(.bottom, 2)

                    Text("还没有待办")
                        .font(TokyoNightTheme.bodyStrong())
                        .foregroundColor(TokyoNightTheme.textSecondary)

                    Text("写下今天第一件值得花时间的事")
                        .font(TokyoNightTheme.small())
                        .foregroundColor(TokyoNightTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(TokyoNightTheme.spacingXL)
            } else {
                ScrollView {
                    LazyVStack(spacing: TokyoNightTheme.spacingS) {
                        ForEach(store.items) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: { store.toggle(todo.id) },
                                onUpdate: { store.update(todo.id, text: $0) },
                                onDelete: { store.delete(todo.id) }
                            )
                        }
                    }
                    .padding(.horizontal, TokyoNightTheme.spacingL)
                    .padding(.vertical, TokyoNightTheme.spacingM)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: TokyoNightTheme.spacingS) {
            Image(systemName: "return")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(TokyoNightTheme.textMuted)

            Text("Enter 添加 · 双击编辑")
                .font(TokyoNightTheme.small())
                .foregroundColor(TokyoNightTheme.textMuted)

            Spacer()

            if store.hasCompleted {
                Button(action: store.clearCompleted) {
                    Text("清除已完成")
                        .font(TokyoNightTheme.small())
                        .foregroundColor(TokyoNightTheme.danger)
                }
                .buttonStyle(.plain)
                .help("删除全部已完成待办")
            }
        }
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: TokyoNightTheme.spacingL) {
            VStack(alignment: .leading, spacing: TokyoNightTheme.spacingS) {
                Text("外观")
                    .font(TokyoNightTheme.small())
                    .foregroundColor(TokyoNightTheme.textSecondary)

                HStack(spacing: TokyoNightTheme.spacingXS) {
                    ForEach(AppearanceMode.allCases) { mode in
                        appearanceButton(mode)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("外观模式")
            }

            VStack(alignment: .leading, spacing: TokyoNightTheme.spacingS) {
                HStack {
                    Text("窗口透明度")
                        .font(TokyoNightTheme.small())
                        .foregroundColor(TokyoNightTheme.textSecondary)

                    Spacer()

                    Text(String(format: "%.0f%%", store.windowAlpha * 100))
                        .font(TokyoNightTheme.counter())
                        .foregroundColor(TokyoNightTheme.textMuted)
                }

                Slider(value: $store.windowAlpha, in: 0.3...1.0)
                    .tint(TokyoNightTheme.accent)
                    .accessibilityLabel("窗口透明度")
            }
        }
    }

    private func appearanceButton(_ mode: AppearanceMode) -> some View {
        let isSelected = store.appearanceMode == mode

        return Button(action: { store.appearanceMode = mode }) {
            HStack(spacing: 5) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 10.5, weight: .semibold))
                Text(mode.label)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? TokyoNightTheme.accent : TokyoNightTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                    .fill(isSelected ? TokyoNightTheme.accentSoft.opacity(0.52) : TokyoNightTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TokyoNightTheme.radiusS, style: .continuous)
                    .stroke(
                        isSelected
                            ? TokyoNightTheme.accent.opacity(0.72)
                            : TokyoNightTheme.border.opacity(0.72),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.label)
        .accessibilityValue(isSelected ? "已选择" : "未选择")
    }

    private var headerSubtitle: String {
        if store.items.isEmpty {
            return "今天想把时间花在哪里？"
        }
        if store.undoneCount == 0 {
            return "今天的计划已经完成"
        }
        return "还有 \(store.undoneCount) 项值得完成"
    }

    private var canAddTodo: Bool {
        !newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addTodo() {
        guard canAddTodo else { return }
        store.add(newTodoText)
        newTodoText = ""
    }
}
