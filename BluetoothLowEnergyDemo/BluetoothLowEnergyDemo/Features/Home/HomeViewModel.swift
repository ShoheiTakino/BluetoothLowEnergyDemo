import SwiftUI
import Observation

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
