import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newTodoText = ""
    @State private var showSettings = false
    @State private var showQuickAdd = false
    @AppStorage("showCompleted") private var showCompleted = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    store.commitEditing()
                }

            if store.compactMode {
                compactView
            } else {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.top, Theme.spacingL)
                        .padding(.bottom, Theme.spacingM)

                    ThemeDivider()

                    inputBar
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.vertical, Theme.spacingM)

                    todoList
                    storageStatus
                    undoBanner

                    ThemeDivider()

                    footer
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.vertical, Theme.spacingM)
                }
            }
        }
        .onChange(of: store.compactMode) { _ in
            showQuickAdd = false
            showSettings = false
        }
        .tint(Theme.accent)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                .stroke(Theme.border.opacity(0.65), lineWidth: Theme.hairline)
        )
    }

    private var viewModeButton: some View {
        Button {
            store.commitEditing()
            store.compactMode.toggle()
        } label: {
            Image(systemName: store.compactMode ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(Theme.textSecondary)
        .help(store.compactMode ? "展开完整列表" : "收起为紧凑视图")
        .accessibilityLabel(store.compactMode ? "展开完整列表" : "收起为紧凑视图")
    }

    private var compactView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("WellSpent")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                Text("· \(store.undoneCount)")
                    .font(Theme.counter())
                    .foregroundColor(Theme.textMuted)
                    .accessibilityLabel("剩余 \(store.undoneCount) 项")
                Spacer(minLength: 4)
                Button { showQuickAdd.toggle() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 24, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.accent)
                .disabled(store.isReadBlocked)
                .help("添加待办")
                .accessibilityLabel("添加待办")
                .popover(isPresented: $showQuickAdd, arrowEdge: .bottom) {
                    inputBar
                        .padding(12)
                        .frame(width: 300)
                        .background(Theme.background)
                        .preferredColorScheme(Theme.colorScheme(for: store.appearanceMode))
                        .onAppear { inputFocused = true }
                }
                Button { showSettings.toggle() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 24, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textMuted)
                .help("打开设置")
                .accessibilityLabel("打开设置")
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    settingsPanel
                        .padding(Theme.spacingL)
                        .frame(width: 280)
                        .background(Theme.background)
                        .preferredColorScheme(Theme.colorScheme(for: store.appearanceMode))
                }
                viewModeButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 3) {
                    storageStatus
                    undoBanner
                    if store.isReadBlocked {
                        EmptyView()
                    } else if store.compactItems.isEmpty {
                        Text(store.items.isEmpty ? "点 + 记下一件事" : "都完成了，休息一下")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    } else {
                        ForEach(store.compactItems) { todo in
                            HStack(spacing: 6) {
                                CompletionToggle(checked: false) { store.toggle(todo.id) }
                                Text(todo.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .help(todo.text)
                                    .onTapGesture(count: 2) { editFromCompact(todo) }
                                    .accessibilityAction(named: "编辑") { editFromCompact(todo) }
                                PriorityMenu(todo: todo)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .contextMenu {
                                Button("编辑") { editFromCompact(todo) }
                                Button("删除") { store.delete(todo.id) }
                            }
                        }
                    }
                }
            }

            Button {
                store.compactMode = false
            } label: {
                Text(store.undoneCount > 3 ? "另有 \(store.undoneCount - 3) 项 · 查看全部" : "查看完整列表")
                    .font(.system(size: 11.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 9)
        }
    }

    private func editFromCompact(_ todo: Todo) {
        store.compactMode = false
        store.beginEditing(todo.id)
    }

    private var header: some View {
        HStack(spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WellSpent")
                    .font(Theme.title())
                    .foregroundColor(Theme.textPrimary)

                Text(headerSubtitle)
                    .font(Theme.small())
                    .foregroundColor(Theme.textMuted)
            }

            Spacer(minLength: Theme.spacingS)

            Text("剩余 \(store.undoneCount) 项")
                .font(Theme.counter())
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Theme.border.opacity(0.72), lineWidth: 1)
                )
                .accessibilityLabel("\(store.undoneCount) 项未完成，共 \(store.items.count) 项")

            viewModeButton

            Button(action: {
                store.commitEditing()
                showSettings.toggle()
            }) {
                Image(systemName: showSettings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(showSettings ? Theme.accent : Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                            .fill(showSettings ? Theme.accentSoft.opacity(0.55) : Theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                            .stroke(
                                showSettings
                                    ? Theme.accent.opacity(0.65)
                                    : Theme.border.opacity(0.72),
                                lineWidth: 1
                            )
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(showSettings ? "收起设置" : "打开设置")
            .accessibilityLabel(showSettings ? "收起设置" : "打开设置")
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                settingsPanel
                    .padding(Theme.spacingL)
                    .frame(width: 280)
                    .background(Theme.background)
                    .preferredColorScheme(Theme.colorScheme(for: store.appearanceMode))
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.accent)
                .frame(width: 22, height: 22)

            TextField(
                "",
                text: $newTodoText,
                prompt: Text("写下一件要做的事…").foregroundColor(Theme.textMuted)
            )
            .textFieldStyle(.plain)
            .font(Theme.body())
            .foregroundColor(Theme.textPrimary)
            .tint(Theme.accent)
            .accessibilityLabel("新待办")
            .focused($inputFocused)
            .onChange(of: inputFocused) { focused in
                if focused { store.commitEditing() }
            }
            .disabled(store.isReadBlocked)
            .onSubmit {
                addTodo()
            }

            Button(action: addTodo) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.onAccent)
                    .frame(width: 29, height: 29)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                            .fill(Theme.buttonFill)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canAddTodo)
            .opacity(canAddTodo ? 1 : 0.42)
            .help("添加待办（Enter）")
            .accessibilityLabel("添加待办")
        }
        .padding(.leading, Theme.spacingS)
        .padding(.trailing, Theme.spacingXS)
        .padding(.vertical, Theme.spacingXS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                .stroke(Theme.border.opacity(0.82), lineWidth: 1)
        )
    }

    private var todoList: some View {
        Group {
            if store.isReadBlocked {
                Text("待办暂时无法读取，请先处理下方提示。")
                    .font(Theme.body())
                    .foregroundColor(Theme.textSecondary)
                    .padding(Theme.spacingXL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.items.isEmpty {
                VStack(spacing: Theme.spacingS) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(Theme.accent)
                        .padding(.bottom, 2)

                    Text("还没有待办")
                        .font(Theme.bodyStrong())
                        .foregroundColor(Theme.textSecondary)

                    Text("写下一件值得花时间的事")
                        .font(Theme.small())
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Theme.spacingXL)
            } else {
                ScrollView {
                    VStack(spacing: Theme.spacingS) {
                        ForEach(store.activeItems) { todo in
                            TodoRow(todo: todo)
                        }
                        if store.hasCompleted {
                            HStack {
                                Button {
                                    store.commitEditing()
                                    showCompleted.toggle()
                                } label: {
                                    Label("已完成 \(store.completedItems.count) 项",
                                          systemImage: showCompleted ? "chevron.down" : "chevron.right")
                                        .font(Theme.small())
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityValue(showCompleted ? "已展开" : "已折叠")
                                Spacer()
                                Button("清除") { store.clearCompleted() }
                                    .buttonStyle(.plain)
                                    .font(Theme.small())
                                    .foregroundColor(Theme.danger)
                                    .help("清除已完成待办，可撤销")
                            }
                            .padding(.top, Theme.spacingS)
                            if showCompleted {
                                ForEach(store.completedItems) { todo in
                                    TodoRow(todo: todo)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingM)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var footer: some View {
        Text("Enter 添加 · 双击编辑")
            .font(Theme.small())
            .foregroundColor(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var undoBanner: some View {
        if let message = store.undoMessage {
            HStack {
                Text(message)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button("撤销") {
                    if store.undoDeletion() { showCompleted = true }
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.accent)
                .disabled(store.isReadBlocked)
            }
            .font(Theme.small())
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .padding(.horizontal, Theme.spacingL)
            .padding(.bottom, Theme.spacingS)
        }
    }

    @ViewBuilder private var storageStatus: some View {
        if let error = store.storageError {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(store.isReadBlocked ? "重新读取" : "重试保存") { store.retryStorage() }
                    Button("打开数据文件夹") { NSWorkspace.shared.open(store.dataDirectory) }
                }
                .tint(Theme.accent)
            }
            .font(Theme.small())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .padding(.horizontal, Theme.spacingL)
            .padding(.bottom, Theme.spacingS)
        } else if let notice = store.storageNotice {
            HStack(alignment: .top) {
                Text(notice)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Button("知道了") { store.dismissNotice() }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.accent)
            }
            .font(Theme.small())
            .foregroundColor(Theme.textSecondary)
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .padding(.horizontal, Theme.spacingL)
            .padding(.bottom, Theme.spacingS)
        }
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            Toggle("窗口置顶", isOn: $store.alwaysOnTop)
                .toggleStyle(.switch)
                .font(Theme.small())
                .foregroundColor(Theme.textSecondary)
            Text(store.alwaysOnTop ? "在各个桌面保持可见" : "像普通窗口一样使用")
                .font(Theme.small())
                .foregroundColor(Theme.textMuted)

            if Theme.supportsAppearanceSelection {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("外观")
                    .font(Theme.small())
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: Theme.spacingXS) {
                    ForEach(AppearanceMode.allCases) { mode in
                        appearanceButton(mode)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("外观模式")
            }
            }

            if !store.compactMode {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    HStack {
                        Text("窗口透明度")
                            .font(Theme.small())
                            .foregroundColor(Theme.textSecondary)

                        Spacer()

                        Text(String(format: "%.0f%%", store.windowAlpha * 100))
                            .font(Theme.counter())
                            .foregroundColor(Theme.textMuted)
                    }

                    Slider(value: $store.windowAlpha, in: 0.3...1.0)
                        .tint(Theme.accent)
                        .accessibilityLabel("窗口透明度")
                }
            }
            Text("WellSpent · v2.2.0")
                .font(Theme.small())
                .foregroundColor(Theme.textMuted)
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
            .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(isSelected ? Theme.accentSoft.opacity(0.52) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .stroke(
                        isSelected
                            ? Theme.accent.opacity(0.72)
                            : Theme.border.opacity(0.72),
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
            return "想把时间花在哪里？"
        }
        if store.undoneCount == 0 {
            return "全部完成，休息一下"
        }
        return "把时间留给值得的事"
    }

    private var canAddTodo: Bool {
        !store.isReadBlocked && !newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addTodo() {
        guard canAddTodo else { return }
        store.add(newTodoText)
        newTodoText = ""
    }
}
