import SwiftUI
import Observation

/// ホーム画面に表示するアプリ機能の定義。
///
/// `id` に `AppRoute` を使うことで、カードタップ時に `router.push(feature.id)` だけで
/// 画面遷移を完結させられる。
struct AppFeature: Identifiable {
    let id: AppRoute
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    static let all: [AppFeature] = [
        AppFeature(
            id: .scanner,
            title: "BLE スキャナー",
            subtitle: "周辺のBluetoothデバイスを検索してRSSIを表示",
            icon: "antenna.radiowaves.left.and.right",
            color: .blue
        ),
        AppFeature(
            id: .chat,
            title: "BLE チャット",
            subtitle: "iPhone2台でメッセージを双方向送受信",
            icon: "message.fill",
            color: .green
        ),
    ]
}

@Observable
@MainActor
final class HomeViewModel {
    let features = AppFeature.all
}
