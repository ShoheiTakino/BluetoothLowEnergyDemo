import Foundation

/// BLE チャットサービスが上位層（ViewModel）に通知するイベント。
///
/// `AsyncStream<BLEChatEvent>` として流れてくるため、
/// ViewModel は `for await event in service.events()` で逐次処理できる。
enum BLEChatEvent: Sendable {
    /// 新しい BLE デバイスが発見されたとき（Central モードのみ）。
    case deviceDiscovered(ScannedDevice)
    case connected(deviceName: String)
    case disconnected
    case readyToSend
    /// 購読中の Central 台数が変化したとき（Peripheral モードのみ）。0 のとき送信不可。
    case centralCountChanged(Int)
    case messageReceived(String)
    case log(String)
}
