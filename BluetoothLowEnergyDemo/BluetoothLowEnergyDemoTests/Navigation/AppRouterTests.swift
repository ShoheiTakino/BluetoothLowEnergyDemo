import Testing
import SwiftUI
@testable import BluetoothLowEnergyDemo

@Suite("AppRouter")
@MainActor
struct AppRouterTests {

    @Test("pushでpathに追加される")
    func pushAddsToPath() {
        let router = AppRouter()
        router.push(.scanner)
        // path に1件追加されているはず
        #expect(router.path.count == 1)
    }

    @Test("連続pushでpathが積まれる")
    func multiplePushes() {
        let router = AppRouter()
        router.push(.scanner)
        router.push(.chat)
        // 2回 push したので path に2件積まれているはず
        #expect(router.path.count == 2)
    }

    @Test("popで1つ減る")
    func popRemovesOne() {
        let router = AppRouter()
        router.push(.scanner)
        router.push(.chat)
        router.pop()
        // pop で末尾が1件取り除かれ、残り1件になっているはず
        #expect(router.path.count == 1)
    }

    @Test("空のpathでpopしても何も起きない")
    func popOnEmptyPathIsNoop() {
        let router = AppRouter()
        router.pop()
        // 空の状態で pop しても path は空のままであるはず
        #expect(router.path.isEmpty)
    }

    @Test("popToRootでpathが空になる")
    func popToRootClearsPath() {
        let router = AppRouter()
        router.push(.scanner)
        router.push(.chat)
        router.push(.chatSession(.central))
        router.popToRoot()
        // 何件積んでいても popToRoot で path が空になるはず
        #expect(router.path.isEmpty)
    }
}
