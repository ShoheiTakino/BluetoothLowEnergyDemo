import CoreBluetooth

protocol ScannerManaging: AnyObject {
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
}

extension CBCentralManager: ScannerManaging {}

protocol ScannerEventHandling: AnyObject {
    func handleStateChange(_ state: CBManagerState)
    func handleDiscovery(id: UUID, name: String?, rssi: Int)
}
