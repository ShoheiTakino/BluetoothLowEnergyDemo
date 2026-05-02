import SwiftUI

/// アプリのナビゲーションルート。
///
/// `NavigationStack` + `navigationDestination(for: AppRoute.self)` により、
/// 遷移先の組み立てをこの1箇所に集約している。
/// 各画面は `router.push(_ route: AppRoute)` を呼ぶだけでよく、
/// 遷移先の具体型を知る必要がない。
struct RootView: View {
    @State private var router = AppRouter()
    let env: AppEnvironment

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .scanner:
                        ScannerView(
                            viewModel: ScannerViewModel(service: env.scannerService)
                        )
                    case .chat:
                        ChatRootView()
                    case .chatSession(let mode):
                        // チャット画面遷移のたびに新しいセッションを生成し、前のセッションの状態を持ち越さない。
                        ChatView(
                            viewModel: ChatViewModel(session: env.chatSessionFactory(mode))
                        )
                    }
                }
        }
        .environment(router)
    }
}
