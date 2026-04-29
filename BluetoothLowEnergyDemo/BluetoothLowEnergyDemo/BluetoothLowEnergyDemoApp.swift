import SwiftUI

@main
struct BluetoothLowEnergyDemoApp: App {
    private let env = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
        }
    }
}
