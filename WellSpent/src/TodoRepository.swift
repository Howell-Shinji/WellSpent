import Foundation

/// Keeps the last valid revision and never treats a read failure as an empty list.
final class TodoRepository {
    struct Loaded {
        let items: [Todo]
        let recovered: Bool
    }

    let directory: URL
    var fileURL: URL { directory.appendingPathComponent("todos.json") }
    var backupURL: URL { directory.appendingPathComponent("todos.backup.json") }
    private let fm = FileManager.default

    init(directory: URL) {
        self.directory = directory
    }

    private func decode(_ data: Data) throws -> [Todo] {
        let items = try JSONDecoder().decode([Todo].self, from: data)
        guard Set(items.map(\.id)).count == items.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return items
    }

    func load() throws -> Loaded {
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let hasMain = fm.fileExists(atPath: fileURL.path)
        if !hasMain && !fm.fileExists(atPath: backupURL.path) {
            return Loaded(items: [], recovered: false)
        }
        do {
            return Loaded(items: try decode(Data(contentsOf: fileURL)), recovered: false)
        } catch {
            // Validate the backup before touching anything. If neither copy can
            // be read, the caller must block writes and offer an explicit retry.
            let backup = try Data(contentsOf: backupURL)
            let items = try decode(backup)
            if hasMain {
                let recovery = directory.appendingPathComponent("todos-recovery-\(UUID().uuidString).json")
                try fm.copyItem(at: fileURL, to: recovery)
            }
            try backup.write(to: fileURL, options: .atomic)
            return Loaded(items: items, recovered: true)
        }
    }

    func save(_ items: [Todo]) throws {
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(items)
        if fm.fileExists(atPath: fileURL.path) {
            let previous = try Data(contentsOf: fileURL)
            _ = try decode(previous)
            // A backup failure must not silently replace the only valid copy.
            try previous.write(to: backupURL, options: .atomic)
        } else {
            try data.write(to: backupURL, options: .atomic)
        }
        try data.write(to: fileURL, options: .atomic)
    }
}
