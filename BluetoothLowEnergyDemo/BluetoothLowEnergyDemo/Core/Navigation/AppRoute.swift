import Foundation

/// アプリ内の画面遷移先を型安全に表す列挙型。
///
/// `Hashable` に適合することで `navigationDestination(for:)` の型引数として使用できる。
/// 新しい画面を追加する場合はここにケースを追加し、
/// `RootView` の `navigationDestination` に対応する View を追加するだけでよい。
enum AppRoute: Hashable {
    case scanner
    case chat
    case chatSession(BLEChatMode)
}
