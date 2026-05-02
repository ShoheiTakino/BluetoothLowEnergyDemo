import CoreBluetooth

// MARK: - Central ブリッジ

/// `CBCentralManagerDelegate`（CoreBluetooth 具体型）を受け取り、
/// `ChatCentralEventHandling`（ドメイン抽象型）に変換して転送するブリッジ。
///
/// `CBPeripheral` の実体をここでキャッシュすることで、
/// サービス層は CBPeripheral を直接保持せず UUID のみで管理できる。
final class ChatCentralBridge: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    weak var handler: (any ChatCentralEventHandling)?

    /// 発見した Peripheral を UUID をキーとして保持するキャッシュ。
    /// `connect(to:)` 時に UUID から実体を引き当てるために使用する。
    private var peripheralCache: [UUID: CBPeripheral] = [:]

    func peripheral(for id: UUID) -> CBPeripheral? {
        peripheralCache[id]
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handler?.chatCentralDidUpdateState(central.state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        peripheralCache[peripheral.identifier] = peripheral
        handler?.chatCentralDidDiscover(
            id: peripheral.identifier,
            name: peripheral.name,
            rssi: RSSI.intValue
        )
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        handler?.chatCentralDidConnect(
            peripheralId: peripheral.identifier,
            peripheralName: peripheral.name
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        handler?.chatCentralDidDisconnect(peripheralId: peripheral.identifier, error: error)
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        handler?.chatCentralDidFailToConnect(peripheralId: peripheral.identifier, error: error)
    }
}

// MARK: - PeripheralManager ブリッジ

/// `CBPeripheralManagerDelegate`（CoreBluetooth 具体型）を受け取り、
/// `ChatPeripheralManagerEventHandling`（ドメイン抽象型）に変換して転送するブリッジ。
///
/// `didReceiveWrite` の処理もここに集約することで、
/// `BLEPeripheralChatService` は `CBPeripheralManagerDelegate` に適合する必要がなくなる。
final class ChatPeripheralManagerBridge: NSObject, CBPeripheralManagerDelegate, @unchecked Sendable {
    weak var handler: (any ChatPeripheralManagerEventHandling)?

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        handler?.chatPeripheralManagerDidUpdateState(peripheral.state)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        handler?.chatPeripheralManagerDidAddService(error: error)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        handler?.chatPeripheralManagerDidSubscribe()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        handler?.chatPeripheralManagerDidUnsubscribe()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for req in requests where req.characteristic.uuid == BLEConstants.messageCharUUID {
            if let data = req.value, let text = String(data: data, encoding: .utf8) {
                handler?.chatPeripheralManagerDidReceiveMessage(text)
            }
            // ATT プロトコルの仕様上、Write リクエストには必ずレスポンスが必要。
            peripheral.respond(to: req, withResult: .success)
        }
    }
}
