import CoreBluetooth
import Foundation

final class BLEScannerService: BLEScannerServiceProtocol {
    private let bridge = ScannerCentralBridge()
    private var manager: (any ScannerManaging)?
    private var continuation: AsyncStream<ScannedDevice>.Continuation?

    typealias ManagerFactory = (CBCentralManagerDelegate) -> any ScannerManaging
    private let managerFactory: ManagerFactory

    init(managerFactory: @escaping ManagerFactory = { delegate in
        CBCentralManager(delegate: delegate, queue: .main)
    }) {
        self.managerFactory = managerFactory
        bridge.handler = self
    }

    func scan() -> AsyncStream<ScannedDevice> {
        AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.continuation = continuation
            self.manager = managerFactory(bridge)
        }
    }

    func stopScan() {
        manager?.stopScan()
        continuation?.finish()
        continuation = nil
        manager = nil
    }
}

extension BLEScannerService: ScannerEventHandling {
    func handleStateChange(_ state: CBManagerState) {
        guard state == .poweredOn else { return }
        manager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    func handleDiscovery(id: UUID, name: String?, rssi: Int) {
        let device = ScannedDevice(id: id, name: name ?? "Unknown", rssi: rssi, discoveredAt: Date())
        continuation?.yield(device)
    }
}
