import Foundation

struct ScannedDevice: Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let discoveredAt: Date
}
