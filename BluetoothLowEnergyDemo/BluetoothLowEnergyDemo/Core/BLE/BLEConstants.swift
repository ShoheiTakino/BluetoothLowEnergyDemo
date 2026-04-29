import CoreBluetooth

enum BLEConstants {
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
    static let messageCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789013")
    static let localName = "BLEDemo"
    /// Peripheral が切断意図を Central に通知するためのシグナル
    static let disconnectSignal = Data([0xFF])
}
