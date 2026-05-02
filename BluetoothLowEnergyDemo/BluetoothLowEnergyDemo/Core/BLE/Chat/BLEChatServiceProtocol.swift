import Foundation

/// Central / Peripheral 両方のチャットセッションが実装する共通インターフェース。
///
/// `events()` は呼び出しごとに新しい `AsyncStream` を返す。
/// `stop()` が呼ばれるとストリームが finish し `for await` ループが終了する。
protocol BLEChatSessionProtocol: AnyObject, Sendable {
    func events() -> AsyncStream<BLEChatEvent>
    func start()
    /// 未接続の場合は `BLEChatError.notConnected` をスローする。
    func sendMessage(_ text: String) async throws
    func stop()
}

/// Central 固有の拡張インターフェース。デバイスへの接続機能を追加する。
protocol BLECentralSessionProtocol: BLEChatSessionProtocol {
    /// 指定した UUID の Peripheral に接続を試みる。
    /// UUID は `BLEChatEvent.deviceDiscovered` で受け取った `ScannedDevice.id` を使う。
    func connect(to deviceID: UUID)
}

/// Peripheral セッションは共通インターフェースで十分なため typealias で定義する。
typealias BLEPeripheralSessionProtocol = BLEChatSessionProtocol

enum BLEChatError: Error {
    case notConnected
}
