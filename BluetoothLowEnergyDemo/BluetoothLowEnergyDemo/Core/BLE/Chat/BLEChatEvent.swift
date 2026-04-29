import Foundation

enum BLEChatEvent: Sendable {
    case deviceDiscovered(ScannedDevice)
    case connected(deviceName: String)
    case disconnected
    case readyToSend
    case centralCountChanged(Int)
    case messageReceived(String)
    case log(String)
}
