import CoreBluetooth
@testable import BluetoothLowEnergyDemo

final class MockChatCentralManaging: ChatCentralManaging {
    private(set) var scanCalled = false
    private(set) var stopScanCalled = false
    private(set) var connectCalled = false
    private(set) var cancelConnectionCalled = false
    private(set) var scannedServiceUUIDs: [CBUUID]?

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanCalled = true
        scannedServiceUUIDs = serviceUUIDs
    }
    func stopScan() { stopScanCalled = true }
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?) { connectCalled = true }
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) { cancelConnectionCalled = true }
}

final class MockChatPeripheralManaging: ChatPeripheralManaging {
    private(set) var addServiceCalled = false
    private(set) var startAdvertisingCalled = false
    private(set) var stopAdvertisingCalled = false
    private(set) var updateValueCalled = false
    private(set) var advertisementData: [String: Any]?

    func add(_ service: CBMutableService) { addServiceCalled = true }
    func startAdvertising(_ advertisementData: [String: Any]?) {
        startAdvertisingCalled = true
        self.advertisementData = advertisementData
    }
    func stopAdvertising() { stopAdvertisingCalled = true }
    @discardableResult
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        updateValueCalled = true
        return true
    }
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {}
}
