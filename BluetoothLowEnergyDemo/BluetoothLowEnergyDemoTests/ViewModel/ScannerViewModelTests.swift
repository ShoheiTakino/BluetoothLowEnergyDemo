import Testing
import Foundation
@testable import BluetoothLowEnergyDemo

// MARK: - Helper

@MainActor
private func makeScanner(
    mock: MockBLEScannerService
) -> (vm: ScannerViewModel, ref: TaskRef) {
    let ref = TaskRef()
    let vm = ScannerViewModel(service: mock) { operation in
        let task = Task { await operation() }
        ref.task = task
        return task
    }
    return (vm, ref)
}

// MARK: - Suite

@Suite("ScannerViewModel")
@MainActor
struct ScannerViewModelTests {

    // MARK: - ライフサイクル

    @Test("stopScanでスキャンが停止しサービスのstopScanが呼ばれる")
    func stopScanCallsService() {
        let mock = MockBLEScannerService()
        let vm = ScannerViewModel(service: mock)

        vm.startScan()
        vm.stopScan()

        // サービスの stopScan が呼ばれているはず
        #expect(mock.stopScanCalled)
        // isScanning が false に戻っているはず
        #expect(vm.isScanning == false)
    }

    @Test("onDisappearでstopScanが呼ばれる")
    func onDisappearCallsStopScan() {
        let mock = MockBLEScannerService()
        let vm = ScannerViewModel(service: mock)

        vm.startScan()
        vm.onDisappear()

        // onDisappear 経由で stopScan が呼ばれているはず
        #expect(mock.stopScanCalled)
        // isScanning が false になっているはず
        #expect(vm.isScanning == false)
    }

    @Test("スキャン完了後にisScanningがfalseになる")
    func isScanningFalseAfterStreamFinishes() async {
        let mock = MockBLEScannerService()
        mock.stubbedDevices = []
        let (vm, ref) = makeScanner(mock: mock)

        vm.startScan()
        // ストリーム開始直後は isScanning が true になっているはず
        #expect(vm.isScanning == true)
        await ref.task?.value

        // ストリーム終了後は isScanning が false に戻っているはず
        #expect(vm.isScanning == false)
    }

    // MARK: - 正常系

    @Test("スキャン開始でデバイスが追加される")
    func scanAddsDevices() async {
        let mock = MockBLEScannerService()
        mock.stubbedDevices = [
            ScannedDevice(id: UUID(), name: "Device A", rssi: -60, discoveredAt: .now),
            ScannedDevice(id: UUID(), name: "Device B", rssi: -75, discoveredAt: .now),
        ]
        let (vm, ref) = makeScanner(mock: mock)

        vm.startScan()
        await ref.task?.value

        // スタブした2件のデバイスが追加されているはず
        #expect(vm.devices.count == 2)
        // 1件目が "Device A" であるはず
        #expect(vm.devices[0].name == "Device A")
        // 2件目が "Device B" であるはず
        #expect(vm.devices[1].name == "Device B")
    }

    @Test("同じUUIDのデバイスはRSSIが最新値に更新される")
    func duplicateDeviceUpdatesRSSI() async {
        let id = UUID()
        let mock = MockBLEScannerService()
        mock.stubbedDevices = [
            ScannedDevice(id: id, name: "Device A", rssi: -60, discoveredAt: .now),
            ScannedDevice(id: id, name: "Device A", rssi: -45, discoveredAt: .now),
        ]
        let (vm, ref) = makeScanner(mock: mock)

        vm.startScan()
        await ref.task?.value

        // 同一 UUID は重複せず1件になっているはず
        #expect(vm.devices.count == 1)
        // RSSI が後から届いた -45 に更新されているはず
        #expect(vm.devices[0].rssi == -45)
    }

    @Test("startScan後にisScanningがtrueになる")
    func isScanningTrueAfterStart() {
        let mock = MockBLEScannerService()
        let vm = ScannerViewModel(service: mock)

        vm.startScan()

        // startScan 直後は isScanning が true になっているはず
        #expect(vm.isScanning == true)
    }

    @Test("startScan時にdevicesがリセットされる")
    func devicesResetOnStartScan() async {
        let id = UUID()
        let mock = MockBLEScannerService()
        mock.stubbedDevices = [
            ScannedDevice(id: id, name: "Device A", rssi: -60, discoveredAt: .now),
        ]
        let (vm, ref) = makeScanner(mock: mock)

        vm.startScan()
        await ref.task?.value
        // 1件スキャン済みであるはず
        #expect(vm.devices.count == 1)

        mock.stubbedDevices = []
        vm.stopScan()
        vm.startScan()
        // 再スキャン開始時に devices がリセットされ空になっているはず
        #expect(vm.devices.isEmpty)
    }

    // MARK: - 異常系

    @Test("startScanを2回呼んでも二重スキャンしない")
    func startScanIsIdempotent() async {
        let mock = MockBLEScannerService()
        mock.stubbedDevices = [
            ScannedDevice(id: UUID(), name: "Device A", rssi: -60, discoveredAt: .now),
        ]
        let (vm, ref) = makeScanner(mock: mock)

        vm.startScan()
        vm.startScan()
        await ref.task?.value

        // 2回呼んでもデバイスは1件しか追加されないはず
        #expect(vm.devices.count == 1)
    }

    @Test("スキャン中でないときstopScanを呼んでもクラッシュしない")
    func stopScanWhenNotScanning() {
        let mock = MockBLEScannerService()
        let vm = ScannerViewModel(service: mock)

        vm.stopScan()

        // 未スキャン状態で stopScan しても isScanning は false のままであるはず
        #expect(vm.isScanning == false)
    }
}
