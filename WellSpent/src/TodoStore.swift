import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    private static let alphaKey = "windowAlpha"
    private static let appearanceKey = "appearanceMode"

    @Published var items: [Todo] = []
    @Published var windowAlpha: Double {
        didSet {
            UserDefaults.standard.set(windowAlpha, forKey: Self.alphaKey)
        }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.appearanceKey)
        }
    }

    var undoneCount: Int { items.filter { !$0.completed }.count }
    var hasCompleted: Bool { items.contains { $0.completed } }

    private let storeURL: URL
    private let encoder: JSONEncoder = JSONEncoder()
    private let decoder: JSONDecoder = JSONDecoder()
    private var saveCancellable: AnyCancellable?

    init() {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
        let supportRoot = appSupport ?? URL(fileURLWithPath: NSHomeDirectory())

        let dir = supportRoot.appendingPathComponent("WellSpent", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storeURL = dir.appendingPathComponent("todos.json")

        let savedAlpha = UserDefaults.standard.object(forKey: Self.alphaKey) as? Double
        self.windowAlpha = savedAlpha ?? 0.95

        let savedAppearance = UserDefaults.standard.string(forKey: Self.appearanceKey)
        self.appearanceMode = AppearanceMode(rawValue: savedAppearance ?? "") ?? .system

        load()

        saveCancellable = $items
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
    }

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(Todo(text: trimmed))
    }

    func toggle(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].completed.toggle()
    }

    func update(_ id: UUID, text: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            items.remove(at: idx)
            return
        }
        items[idx].text = trimmed
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clearCompleted() {
        items.removeAll { $0.completed }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        if let decoded = try? decoder.decode([Todo].self, from: data) {
            self.items = decoded
        }
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
