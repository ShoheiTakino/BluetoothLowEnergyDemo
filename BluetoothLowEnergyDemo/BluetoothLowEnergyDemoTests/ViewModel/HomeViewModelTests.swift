import Testing
@testable import BluetoothLowEnergyDemo

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

    @Test("featuresが2件含まれる")
    func featureCountIsTwo() {
        let vm = HomeViewModel()
        // Scanner と Chat の2件が登録されているはず
        #expect(vm.features.count == 2)
    }

    @Test("featuresにscannerが含まれる")
    func featuresContainsScanner() {
        let vm = HomeViewModel()
        // features に .scanner ルートを持つ要素が含まれているはず
        #expect(vm.features.contains(where: { $0.id == .scanner }))
    }

    @Test("featuresにchatが含まれる")
    func featuresContainsChat() {
        let vm = HomeViewModel()
        // features に .chat ルートを持つ要素が含まれているはず
        #expect(vm.features.contains(where: { $0.id == .chat }))
    }
}
