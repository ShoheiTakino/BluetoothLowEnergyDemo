import CoreBluetooth

// MARK: - Central 操作の抽象化

protocol ChatCentralManaging: AnyObject {
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
}

extension CBCentralManager: ChatCentralManaging {}

// MARK: - PeripheralManager 操作の抽象化

protocol ChatPeripheralManaging: AnyObject {
    func add(_ service: CBMutableService)
    func startAdvertising(_ advertisementData: [String: Any]?)
    func stopAdvertising()
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code)
}

extension CBPeripheralManager: ChatPeripheralManaging {}

// MARK: - Central イベントの抽象化

protocol ChatCentralEventHandling: AnyObject {
    func chatCentralDidUpdateState(_ state: CBManagerState)
    func chatCentralDidDiscover(id: UUID, name: String?, rssi: Int)
    func chatCentralDidConnect(peripheralId: UUID, peripheralName: String?)
    func chatCentralDidDisconnect(peripheralId: UUID, error: Error?)
    func chatCentralDidFailToConnect(peripheralId: UUID, error: Error?)
}

// MARK: - PeripheralManager イベントの抽象化

protocol ChatPeripheralManagerEventHandling: AnyObject {
    func chatPeripheralManagerDidUpdateState(_ state: CBManagerState)
    func chatPeripheralManagerDidAddService(error: Error?)
    func chatPeripheralManagerDidSubscribe()
    func chatPeripheralManagerDidUnsubscribe()
    func chatPeripheralManagerDidReceiveMessage(_ text: String)
}
