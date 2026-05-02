import Foundation

/// BLE チャットの動作モードを表す。
/// `Hashable` により `AppRoute.chatSession(BLEChatMode)` の関連値として `NavigationPath` に積める。
enum BLEChatMode: Hashable, Sendable {
    case central
    case peripheral
}
