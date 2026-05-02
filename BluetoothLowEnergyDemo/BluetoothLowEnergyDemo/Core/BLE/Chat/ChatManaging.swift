import CoreBluetooth

// MARK: - Central 操作の抽象化

/// `CBCentralManager` の操作を抽象化するプロトコル。テスト時は Mock に差し替えられる。
protocol ChatCentralManaging: AnyObject {
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
}

extension CBCentralManager: ChatCentralManaging {}

// MARK: - PeripheralManager 操作の抽象化

/// `CBPeripheralManager` の操作を抽象化するプロトコル。テスト時は Mock に差し替えられる。
protocol ChatPeripheralManaging: AnyObject {
    func add(_ service: CBMutableService)
    func startAdvertising(_ advertisementData: [String: Any]?)
    func stopAdvertising()
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code)
}

extension CBPeripheralManager: ChatPeripheralManaging {}

// MARK: - Central イベントの抽象化

/// `CBCentralManagerDelegate` のコールバックを CoreBluetooth 型から分離した形で受け取るプロトコル。
///
/// `ChatCentralBridge` がデリゲートを受け取り、このプロトコルに変換して転送する。
/// `CBPeripheral` は渡さず UUID のみ渡すことで、サービス層が CBPeripheral に依存しない設計にしている。
protocol ChatCentralEventHandling: AnyObject {
    func chatCentralDidUpdateState(_ state: CBManagerState)
    func chatCentralDidDiscover(id: UUID, name: String?, rssi: Int)
    func chatCentralDidConnect(peripheralId: UUID, peripheralName: String?)
    func chatCentralDidDisconnect(peripheralId: UUID, error: Error?)
    func chatCentralDidFailToConnect(peripheralId: UUID, error: Error?)
}

// MARK: - PeripheralManager イベントの抽象化

/// `CBPeripheralManagerDelegate` のコールバックを CoreBluetooth 型から分離した形で受け取るプロトコル。
protocol ChatPeripheralManagerEventHandling: AnyObject {
    func chatPeripheralManagerDidUpdateState(_ state: CBManagerState)
    func chatPeripheralManagerDidAddService(error: Error?)
    func chatPeripheralManagerDidSubscribe()
    func chatPeripheralManagerDidUnsubscribe()
    func chatPeripheralManagerDidReceiveMessage(_ text: String)
}
