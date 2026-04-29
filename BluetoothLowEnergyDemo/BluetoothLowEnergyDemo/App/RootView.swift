import SwiftUI

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
                        ChatView(
                            viewModel: ChatViewModel(session: env.chatSessionFactory(mode))
                        )
                    }
                }
        }
        .environment(router)
    }
}
