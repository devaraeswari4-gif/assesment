import Foundation

struct ScanRecord: Codable, Equatable {
    let id: UUID
    let name: String
    let status: Bool
    let date: Date

    init(id: UUID = UUID(), name: String, status: Bool, date: Date) {
        self.id = id
        self.name = name
        self.status = status
        self.date = date
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, status, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(Bool.self, forKey: .status)
        date = try container.decode(Date.self, forKey: .date)
    }
}

final class StorageManager {
    static let shared = StorageManager()
    private let key = "scan_history"

    func save(_ record: ScanRecord) {
        var all = fetch()
        all.append(record)
        persist(all)
    }

    func fetch() -> [ScanRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScanRecord].self, from: data)
        else { return [] }
        return decoded
    }

    func delete(id: UUID) {
        var all = fetch()
        all.removeAll { $0.id == id }
        persist(all)
    }

    private func persist(_ records: [ScanRecord]) {
        let data = try? JSONEncoder().encode(records)
        UserDefaults.standard.set(data, forKey: key)
    }
}
