import Foundation

enum TodoPriority: String, CaseIterable, Codable {
    case high
    case normal
    case low

    var sortRank: Int {
        switch self {
        case .high: return 0
        case .normal: return 1
        case .low: return 2
        }
    }

    var title: String {
        switch self {
        case .high: return "高优先级"
        case .normal: return "普通"
        case .low: return "低优先级"
        }
    }

    var shortTitle: String {
        switch self {
        case .high: return "高"
        case .normal: return "普通"
        case .low: return "低"
        }
    }
}

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var completed: Bool
    var priority: TodoPriority
    var createdAt: Date

    init(id: UUID = UUID(), text: String, completed: Bool = false,
         priority: TodoPriority = .normal, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.completed = completed
        self.priority = priority
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, completed, priority, createdAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        text = try values.decode(String.self, forKey: .text)
        completed = try values.decode(Bool.self, forKey: .completed)
        priority = try values.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .normal
        createdAt = try values.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(text, forKey: .text)
        try values.encode(completed, forKey: .completed)
        try values.encode(priority, forKey: .priority)
        try values.encode(createdAt, forKey: .createdAt)
    }
}
