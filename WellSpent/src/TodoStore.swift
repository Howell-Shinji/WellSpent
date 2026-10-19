import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [Todo] = []
    @Published private(set) var storageError: String?
    @Published private(set) var storageNotice: String?
    @Published private(set) var isReadBlocked = false
    @Published private(set) var hasUnsavedChanges = false
    @Published private(set) var undoMessage: String?
    @Published private(set) var editingID: UUID?
    @Published var editDraft = ""

    @Published var windowAlpha: Double {
        didSet { defaults.set(windowAlpha, forKey: "windowAlpha") }
    }
    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet {
            if Theme.supportsAppearanceSelection {
                defaults.set(appearanceMode.rawValue, forKey: "appearanceMode")
            }
        }
    }

    var activeItems: [Todo] {
        items.enumerated()
            .filter { !$0.element.completed }
            .sorted {
                let left = $0.element.priority.sortRank
                let right = $1.element.priority.sortRank
                return left == right ? $0.offset < $1.offset : left < right
            }
            .map { $0.element }
    }
    var completedItems: [Todo] { items.filter(\.completed) }
    var undoneCount: Int { activeItems.count }
    var hasCompleted: Bool { items.contains(where: \.completed) }
    var dataDirectory: URL { repository.directory }

    private let defaults: UserDefaults
    private let repository: TodoRepository
    private let undoDuration: Duration
    private var deletedBatches: [[(index: Int, item: Todo)]] = []
    private var undoExpiryTask: Task<Void, Never>?

    init(directory: URL? = nil, defaults: UserDefaults = .standard,
         undoDuration: Duration = .seconds(5)) {
        self.defaults = defaults
        self.undoDuration = undoDuration
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory,
                                                         in: .userDomainMask)[0]
            .appendingPathComponent("WellSpent", isDirectory: true)
        repository = TodoRepository(directory: root)
        let alpha = defaults.object(forKey: "windowAlpha") as? Double ?? Theme.defaultAlpha
        windowAlpha = alpha.isFinite ? min(1, max(0.3, alpha)) : Theme.defaultAlpha
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? true
        appearanceMode = Theme.supportsAppearanceSelection
            ? AppearanceMode(rawValue: defaults.string(forKey: "appearanceMode") ?? "") ?? .system
            : .light
        load()
    }

    func add(_ text: String) {
        guard !isReadBlocked else { return }
        commitEditing()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(Todo(text: trimmed))
        changed()
    }

    func toggle(_ id: UUID) {
        guard !isReadBlocked else { return }
        commitEditing()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].completed.toggle()
        changed()
    }

    func setPriority(_ priority: TodoPriority, for id: UUID) {
        guard !isReadBlocked else { return }
        commitEditing()
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].priority != priority else { return }
        items[index].priority = priority
        changed()
    }

    func update(_ id: UUID, text: String) {
        guard !isReadBlocked,
              let index = items.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Empty edits cancel the change; deletion always requires its own action.
        guard !trimmed.isEmpty, items[index].text != trimmed else { return }
        items[index].text = trimmed
        changed()
    }

    func beginEditing(_ id: UUID) {
        guard !isReadBlocked, editingID != id else { return }
        commitEditing()
        guard let item = items.first(where: { $0.id == id }) else { return }
        editDraft = item.text
        editingID = id
    }

    func commitEditing(ifMatching id: UUID? = nil) {
        guard let current = editingID, id == nil || current == id else { return }
        let text = editDraft
        editingID = nil
        editDraft = ""
        update(current, text: text)
    }

    func cancelEditing(_ id: UUID) {
        guard editingID == id else { return }
        editingID = nil
        editDraft = ""
    }

    func delete(_ id: UUID) {
        remove { $0.id == id }
    }

    func clearCompleted() {
        remove { $0.completed }
    }

    private func remove(where predicate: (Todo) -> Bool) {
        guard !isReadBlocked else { return }
        commitEditing()
        let removed = items.enumerated().compactMap { index, item in
            predicate(item) ? (index: index, item: item) : nil
        }
        guard !removed.isEmpty else { return }
        deletedBatches.append(removed)
        let ids = Set(removed.map { $0.item.id })
        items.removeAll { ids.contains($0.id) }
        undoMessage = "已删除 \(deletedBatches.reduce(0) { $0 + $1.count }) 项"
        scheduleUndoExpiry()
        changed()
    }

    private func scheduleUndoExpiry() {
        undoExpiryTask?.cancel()
        let duration = undoDuration
        undoExpiryTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.deletedBatches = []
            self?.undoMessage = nil
            self?.undoExpiryTask = nil
        }
    }

    @discardableResult
    func undoDeletion() -> Bool {
        guard !isReadBlocked, !deletedBatches.isEmpty else { return false }
        commitEditing()
        undoExpiryTask?.cancel()
        undoExpiryTask = nil
        var restoredCompleted = false
        for batch in deletedBatches.reversed() {
            for removed in batch where !items.contains(where: { $0.id == removed.item.id }) {
                items.insert(removed.item, at: min(removed.index, items.count))
                restoredCompleted = restoredCompleted || removed.item.completed
            }
        }
        deletedBatches = []
        undoMessage = nil
        changed()
        return restoredCompleted
    }

    func dismissNotice() { storageNotice = nil }

    func retryStorage() {
        if isReadBlocked {
            load()
        } else {
            _ = flush()
        }
    }

    private func load() {
        do {
            let loaded = try repository.load()
            items = loaded.items
            isReadBlocked = false
            storageError = nil
            storageNotice = loaded.recovered ? "已从备份恢复待办，原文件已保留。" : nil
        } catch {
            isReadBlocked = true
            storageError = "暂时无法读取待办。原文件未被覆盖，请重试或查看数据文件夹。"
        }
    }

    private func changed() {
        hasUnsavedChanges = true
        _ = flush()
    }

    @discardableResult
    func flush() -> Bool {
        guard hasUnsavedChanges else { return true }
        guard !isReadBlocked else { return false }
        do {
            try repository.save(items)
            hasUnsavedChanges = false
            storageError = nil
            return true
        } catch {
            storageError = "更改尚未保存，仍保留在当前窗口中。请重试保存。"
            return false
        }
    }
}
