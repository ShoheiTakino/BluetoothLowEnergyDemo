import CoreBluetooth

/// `CBCentralManager` のスキャン操作を抽象化するプロトコル。テスト時は Mock に差し替えられる。
protocol ScannerManaging: AnyObject {
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
}

extension CBCentralManager: ScannerManaging {}

/// `ScannerCentralBridge` から `BLEScannerService` へイベントを伝達するプロトコル。
///
/// `CBPeripheral` を渡さず UUID・name・rssi のみ受け渡すことで、
/// サービス層が CBPeripheral に依存しない設計にしている。
protocol ScannerEventHandling: AnyObject {
    func handleStateChange(_ state: CBManagerState)
    func handleDiscovery(id: UUID, name: String?, rssi: Int)
}
