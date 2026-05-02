import SwiftUI
import Observation

/// `NavigationPath` のラッパーとして、アプリ全体の画面スタックを管理する。
///
/// `@Observable` により View が `path` の変化を自動的に検知して再描画される。
/// `@Environment(AppRouter.self)` で任意の子 View から参照でき、
/// ナビゲーションロジックのテストが `AppRouter` 単体で行えるようになる。
@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
