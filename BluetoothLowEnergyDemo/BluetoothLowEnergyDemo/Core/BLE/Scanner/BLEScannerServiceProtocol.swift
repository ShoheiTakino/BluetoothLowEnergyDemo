import Foundation

protocol BLEScannerServiceProtocol: AnyObject, Sendable {
    func scan() -> AsyncStream<ScannedDevice>
    func stopScan()
}
