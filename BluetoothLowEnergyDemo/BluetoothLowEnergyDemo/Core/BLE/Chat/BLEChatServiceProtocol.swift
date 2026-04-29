import Foundation

/// Shared interface for both Central and Peripheral chat sessions.
protocol BLEChatSessionProtocol: AnyObject, Sendable {
    func events() -> AsyncStream<BLEChatEvent>
    func start()
    func sendMessage(_ text: String) async throws
    func stop()
}

/// Central-specific extension: adds device connection capability.
protocol BLECentralSessionProtocol: BLEChatSessionProtocol {
    func connect(to deviceID: UUID)
}

/// Peripheral session uses the base protocol without additional methods.
typealias BLEPeripheralSessionProtocol = BLEChatSessionProtocol

enum BLEChatError: Error {
    case notConnected
}
