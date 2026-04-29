import Foundation

struct BLEMessage: Identifiable, Sendable {
    let id: UUID
    let text: String
    let isSent: Bool
    let timestamp: Date

    init(text: String, isSent: Bool, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isSent = isSent
        self.timestamp = timestamp
    }
}
