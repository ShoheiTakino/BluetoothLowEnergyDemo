import CoreBluetooth

/// BLEの操作を定義するインターフェース（Data層への依存を逆転させる）
protocol BLEServiceProtocol: AnyObject {
    var delegate: (any BLEServiceDelegate)? { get set }
    func startAsCentral()
    func startAsPeripheral()
    func stop()
    func connect(to peripheral: CBPeripheral)
    /// - Returns: 送信に成功した場合 true
    func sendMessage(_ text: String) -> Bool
}

/// BLEServiceからViewModel(Presentation層)へのイベント通知
protocol BLEServiceDelegate: AnyObject {
    func bleService(didDiscover peripheral: CBPeripheral, rssi: Int)
    func bleServiceDidConnect(peripheral: CBPeripheral)
    func bleServiceDidDisconnect()
    func bleServiceDidBecomeReady()
    func bleServiceCentralCountChanged(_ count: Int)
    func bleServiceDidReceive(message: String)
    func bleServiceDidLog(_ message: String)
}
