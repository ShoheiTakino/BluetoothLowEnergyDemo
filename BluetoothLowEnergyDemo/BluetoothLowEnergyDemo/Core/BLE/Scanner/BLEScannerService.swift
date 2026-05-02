import CoreBluetooth
import Foundation

/// BLE スキャンの実装クラス。
///
/// `CBCentralManager` を直接保持せず `ScannerManaging` プロトコル越しに操作する。
/// デリゲートは `ScannerCentralBridge` に委譲し、CBCentralManager への依存を分離している。
/// スキャン結果は `AsyncStream<ScannedDevice>` として上位層に流す。
final class BLEScannerService: BLEScannerServiceProtocol {
    private let bridge = ScannerCentralBridge()
    private var manager: (any ScannerManaging)?
    private var continuation: AsyncStream<ScannedDevice>.Continuation?

    typealias ManagerFactory = (CBCentralManagerDelegate) -> any ScannerManaging
    private let managerFactory: ManagerFactory

    init(managerFactory: @escaping ManagerFactory = { delegate in
        // queue: .main を指定することで、デリゲートコールバックが常にメインスレッドで呼ばれる。
        CBCentralManager(delegate: delegate, queue: .main)
    }) {
        self.managerFactory = managerFactory
        bridge.handler = self
    }

    func scan() -> AsyncStream<ScannedDevice> {
        AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.continuation = continuation
            // scan() 呼び出し時に CBCentralManager を初期化することで、
            // Bluetooth の状態確認と poweredOn 後のスキャン開始を自動的に行う。
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
            // 同一デバイスを RSSI 更新のたびに重複して受け取るため true に設定。
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    func handleDiscovery(id: UUID, name: String?, rssi: Int) {
        let device = ScannedDevice(id: id, name: name ?? "Unknown", rssi: rssi, discoveredAt: Date())
        continuation?.yield(device)
    }
}
