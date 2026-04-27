import Foundation

enum BLEMode {
    case idle, central, peripheral
}

struct BLEMessage: Identifiable {
    let id = UUID()
    let text: String
    let isSent: Bool
    let timestamp = Date()
}
