import Foundation
import AppKit

@main
struct RegressionTests {
    @MainActor
    static func main() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("wellspent-tests-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let suite = "WellSpent.Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var count = 0

        func expect(_ condition: Bool, _ message: String) {
            guard condition else { fatalError("FAIL: \(message)") }
            count += 1
        }
        func directory(_ name: String) -> URL { root.appendingPathComponent(name) }
        func read(_ directory: URL) throws -> [Todo] {
            try JSONDecoder().decode([Todo].self,
                                     from: Data(contentsOf: directory.appendingPathComponent("todos.json")))
        }

        let normal = directory("normal")
        let store = TodoStore(directory: normal, defaults: defaults)
        store.add("  第一项  ")
        store.add("第二项")
        let first = store.items[0].id
        let second = store.items[1].id
        let saved = try read(normal)
        expect(saved.map(\.text) == ["第一项", "第二项"], "writes finish before add returns")
        expect(!store.hasUnsavedChanges, "successful save is acknowledged")
        store.delete(first)
        store.add("后来新增")
        store.undoDeletion()
        expect(store.items.map(\.text) == ["第一项", "第二项", "后来新增"], "undo preserves later additions and order")
        expect(store.undoMessage == nil, "undo consumed once")
        store.toggle(first)
        store.toggle(second)
        store.clearCompleted()
        store.add("清理后新增")
        store.undoDeletion()
        expect(store.items.map(\.text) == ["第一项", "第二项", "后来新增", "清理后新增"], "batch undo restores original order")
        expect(store.completedItems.count == 2, "batch undo preserves completion state")

        let timed = TodoStore(directory: directory("timed-undo"), defaults: defaults,
                              undoDuration: .milliseconds(120))
        timed.add("先删除")
        timed.add("后删除")
        let firstTimedID = timed.items[0].id
        let secondTimedID = timed.items[1].id
        timed.delete(firstTimedID)
        try await Task.sleep(for: .milliseconds(70))
        timed.delete(secondTimedID)
        try await Task.sleep(for: .milliseconds(80))
        expect(timed.undoMessage != nil, "a new deletion restarts the undo window")
        try await Task.sleep(for: .milliseconds(80))
        expect(timed.undoMessage == nil, "undo banner expires after a short delay")
        timed.undoDeletion()
        expect(timed.items.isEmpty, "expired deletion cannot be undone")

        store.beginEditing(first)
        store.editDraft = "已修改"
        store.beginEditing(second)
        expect(store.items[0].text == "已修改", "switching editors commits the previous draft")
        store.editDraft = "不保存"
        store.commitEditing(ifMatching: first)
        expect(store.editingID == second, "stale focus callback cannot commit a newer editor")
        store.cancelEditing(second)
        store.commitEditing(ifMatching: second)
        expect(store.items[1].text == "第二项", "cancel survives a subsequent focus-loss callback")
        store.beginEditing(second)
        store.editDraft = " \n "
        store.commitEditing()
        expect(store.items.count == 4 && store.items[1].text == "第二项", "empty edits never delete")
        store.beginEditing(second)
        store.editDraft = "退出前的修改"
        store.commitEditing()
        expect(store.flush(), "exit flush succeeds")
        let reopened = TodoStore(directory: normal, defaults: defaults)
        expect(reopened.items[1].text == "退出前的修改", "last edit is durable without a run loop")

        let recovery = directory("recovery")
        let recoveryStore = TodoStore(directory: recovery, defaults: defaults)
        recoveryStore.add("备份中的任务")
        recoveryStore.add("最新任务")
        let corrupted = Data("broken json".utf8)
        try corrupted.write(to: recovery.appendingPathComponent("todos.json"))
        let recovered = TodoStore(directory: recovery, defaults: defaults)
        expect(recovered.items.map(\.text) == ["备份中的任务"], "valid previous revision recovers")
        expect(recovered.storageNotice != nil && !recovered.isReadBlocked, "recovery is visible")
        let preserved = try fm.contentsOfDirectory(at: recovery, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("todos-recovery-") }
        expect(preserved.count == 1, "corrupt original is preserved")
        let preservedData = try Data(contentsOf: preserved[0])
        expect(preservedData == corrupted, "recovery copy is byte-for-byte original")

        let blocked = directory("blocked")
        try fm.createDirectory(at: blocked, withIntermediateDirectories: true)
        try corrupted.write(to: blocked.appendingPathComponent("todos.json"))
        let blockedStore = TodoStore(directory: blocked, defaults: defaults)
        blockedStore.add("不得覆盖")
        expect(blockedStore.isReadBlocked && blockedStore.items.isEmpty, "read failure blocks mutations")
        let stillCorrupt = try Data(contentsOf: blocked.appendingPathComponent("todos.json"))
        expect(stillCorrupt == corrupted, "failed read never overwrites original")
        let repair = [Todo(text: "修复后的内容")]
        try JSONEncoder().encode(repair).write(to: blocked.appendingPathComponent("todos.json"))
        blockedStore.retryStorage()
        expect(!blockedStore.isReadBlocked && blockedStore.items == repair, "explicit retry reloads repaired data")

        let writeFail = directory("write-fail")
        let writeStore = TodoStore(directory: writeFail, defaults: defaults)
        writeStore.add("已有任务")
        let moved = directory("write-fail-original")
        try fm.moveItem(at: writeFail, to: moved)
        try Data("not a directory".utf8).write(to: writeFail)
        writeStore.add("写入失败仍保留")
        expect(writeStore.hasUnsavedChanges && writeStore.storageError != nil, "write failure is visible and dirty")
        expect(!writeStore.flush(), "exit cannot silently accept a failed save")
        expect(writeStore.items.count == 2, "failed write retains changes in memory")
        try fm.removeItem(at: writeFail)
        try fm.moveItem(at: moved, to: writeFail)
        writeStore.retryStorage()
        let retried = try read(writeFail)
        expect(!writeStore.hasUnsavedChanges && retried.count == 2, "retry persists retained edits")

        defaults.set(false, forKey: "alwaysOnTop")
        defaults.set(0.72, forKey: "windowAlpha")
        let preferences = TodoStore(directory: directory("prefs"), defaults: defaults)
        expect(!preferences.alwaysOnTop && preferences.windowAlpha == 0.72, "window preferences survive relaunch")
        if !Theme.supportsAppearanceSelection {
            defaults.set("dark", forKey: "appearanceMode")
            let fixed = TodoStore(directory: directory("fixed"), defaults: defaults)
            expect(fixed.appearanceMode == .light, "Lavender ignores saved dark mode")
        }

        let primary = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let external = NSRect(x: 1440, y: 0, width: 1920, height: 1080)
        let desired = NSRect(x: 1600, y: 100, width: 500, height: 600)
        expect(WindowGeometry.fitted(desired, screens: [primary, external]) == desired, "connected external placement is kept")
        let fallback = WindowGeometry.fitted(desired, screens: [primary])
        expect(primary.contains(fallback), "disconnected display falls back fully on screen")
        let oversized = WindowGeometry.fitted(NSRect(x: -100, y: -100, width: 3000, height: 2000), screens: [primary])
        expect(primary.contains(oversized), "oversized saved frames fit the available screen")
        expect(!WindowGeometry.isValid(.zero), "invalid stored geometry is rejected")
        print("PASS: \(count) regression checks (\(Theme.supportsAppearanceSelection ? "Tokyo Night" : "Lavender"))")
    }
}
