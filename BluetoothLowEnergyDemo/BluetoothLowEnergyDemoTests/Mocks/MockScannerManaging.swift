import CoreBluetooth
@testable import BluetoothLowEnergyDemo

final class MockScannerManaging: ScannerManaging {
    private(set) var scanCalled = false
    private(set) var stopScanCalled = false
    private(set) var scannedServiceUUIDs: [CBUUID]?

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanCalled = true
        scannedServiceUUIDs = serviceUUIDs
    }

    func stopScan() {
        stopScanCalled = true
    }
}
