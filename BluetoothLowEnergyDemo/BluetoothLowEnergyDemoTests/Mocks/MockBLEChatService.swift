import Foundation
@testable import BluetoothLowEnergyDemo

@MainActor
final class MockBLECentralSession: BLECentralSessionProtocol {
    var eventsContinuation: AsyncStream<BLEChatEvent>.Continuation?
    var shouldThrowOnSend = false
    private(set) var sentMessages: [String] = []
    private(set) var startCalled = false
    private(set) var stopCalled = false
    private(set) var connectedDeviceID: UUID?

    func events() -> AsyncStream<BLEChatEvent> {
        AsyncStream { [weak self] continuation in
            MainActor.assumeIsolated { self?.eventsContinuation = continuation }
        }
    }

    func start() { startCalled = true }
    func connect(to deviceID: UUID) { connectedDeviceID = deviceID }
    func sendMessage(_ text: String) async throws {
        if shouldThrowOnSend { throw BLEChatError.notConnected }
        sentMessages.append(text)
    }
    func stop() { stopCalled = true }
}

@MainActor
final class MockBLEPeripheralSession: BLEPeripheralSessionProtocol {
    var eventsContinuation: AsyncStream<BLEChatEvent>.Continuation?
    private(set) var sentMessages: [String] = []
    private(set) var startCalled = false
    private(set) var stopCalled = false

    func events() -> AsyncStream<BLEChatEvent> {
        AsyncStream { [weak self] continuation in
            MainActor.assumeIsolated { self?.eventsContinuation = continuation }
        }
    }

    func start() { startCalled = true }
    func sendMessage(_ text: String) async throws { sentMessages.append(text) }
    func stop() { stopCalled = true }
}
