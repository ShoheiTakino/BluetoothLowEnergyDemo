import CoreBluetooth

/// `CBCentralManagerDelegate`（CoreBluetooth 具体型）を受け取り、
/// `ScannerEventHandling`（ドメイン抽象型）に変換して転送するブリッジ。
///
/// このブリッジを挟むことで `BLEScannerService` は `CBCentralManager` に直接依存しない。
final class ScannerCentralBridge: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    weak var handler: (any ScannerEventHandling)?

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handler?.handleStateChange(central.state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // peripheral.name が nil の場合はアドバタイズデータからローカル名を取得する。
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        handler?.handleDiscovery(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
    }
}
