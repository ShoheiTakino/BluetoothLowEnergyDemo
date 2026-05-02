import SwiftUI

/// アプリのエントリーポイント。
///
/// `AppEnvironment.live` をここで1度だけ生成し、`RootView` に渡す。
/// アプリが kill されるまで同じインスタンスを保持し続けることで、
/// スキャンサービスなどのシングルトン的な依存がアプリ全体で共有される。
@main
struct BluetoothLowEnergyDemoApp: App {
    private let env = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
        }
    }
}
