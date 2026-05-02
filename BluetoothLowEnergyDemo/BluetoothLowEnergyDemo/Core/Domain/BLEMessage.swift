import Foundation

/// チャット画面で表示するメッセージを表す値型。
///
/// `id` と `timestamp` にデフォルト引数を持つ init を提供することで、
/// テスト時に固定値を注入でき、決定論的な検証が可能になる。
struct BLEMessage: Identifiable, Sendable {
    let id: UUID
    let text: String
    /// `true` のとき自分が送信したメッセージ、`false` のとき相手から受信したメッセージ。
    let isSent: Bool
    let timestamp: Date

    init(text: String, isSent: Bool, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isSent = isSent
        self.timestamp = timestamp
    }
}
