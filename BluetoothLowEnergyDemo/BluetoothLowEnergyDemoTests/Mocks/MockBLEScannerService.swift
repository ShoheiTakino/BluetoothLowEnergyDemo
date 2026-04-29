import Foundation
@testable import BluetoothLowEnergyDemo

@MainActor
final class MockBLEScannerService: BLEScannerServiceProtocol {
    var stubbedDevices: [ScannedDevice] = []
    private(set) var stopScanCalled = false

    func scan() -> AsyncStream<ScannedDevice> {
        let devices = stubbedDevices
        return AsyncStream { continuation in
            for device in devices {
                continuation.yield(device)
            }
            continuation.finish()
        }
    }

    func stopScan() {
        stopScanCalled = true
    }
}
