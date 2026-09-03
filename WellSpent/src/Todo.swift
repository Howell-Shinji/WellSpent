import Foundation

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var completed: Bool
    var createdAt: Date

    init(id: UUID = UUID(), text: String, completed: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.completed = completed
        self.createdAt = createdAt
    }
}
