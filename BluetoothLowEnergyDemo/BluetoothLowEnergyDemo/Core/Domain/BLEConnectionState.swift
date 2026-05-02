import Foundation

/// BLE チャットセッションの接続状態を表す。Central モードでのみ状態遷移が発生する。
/// Peripheral モードは `subscribedCentralCount` で接続状態を管理するため、このenumは不使用。
enum BLEConnectionState: Sendable {
    case disconnected
    case connecting
    /// Notify 登録が完了し、メッセージの送受信が可能な状態。
    case ready
}
