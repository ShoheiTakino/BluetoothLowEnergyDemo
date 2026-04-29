import Testing
import Foundation
import CoreBluetooth
@testable import BluetoothLowEnergyDemo

@Suite("BLEScannerService")
@MainActor
struct BLEScannerServiceTests {

    // MARK: - ライフサイクル

    @Test("stopScanを呼ぶとscanストリームが終了する")
    func stopScanFinishesStream() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }
        var streamFinished = false

        let ref = TaskRef()
        ref.task = Task {
            for await _ in service.scan() {}
            streamFinished = true
        }
        await Task.yield()
        service.stopScan()
        await ref.task?.value

        // ストリームが終端まで消費され finished になっているはず
        #expect(streamFinished)
        // manager の stopScan が呼ばれているはず
        #expect(mock.stopScanCalled)
    }

    @Test("stopScanを複数回呼んでもクラッシュしない")
    func stopScanIsIdempotent() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }

        let ref = TaskRef()
        ref.task = Task { for await _ in service.scan() {} }
        await Task.yield()

        service.stopScan()
        service.stopScan()
        await ref.task?.value
        // 2回呼んでもクラッシュせず正常終了しているはず（テストが通ること自体が期待）
    }

    // MARK: - 正常系

    @Test("poweredOnでscanForPeripheralsが呼ばれる")
    func poweredOnStartsScan() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }

        let ref = TaskRef()
        ref.task = Task { for await _ in service.scan() {} }
        await Task.yield()

        service.handleStateChange(.poweredOn)

        // Bluetooth が poweredOn になったらスキャンが開始されるはず
        #expect(mock.scanCalled)
        service.stopScan()
        await ref.task?.value
    }

    @Test("デバイス検出でScannedDeviceがストリームに流れる")
    func discoveryYieldsDevice() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }
        var discovered: [ScannedDevice] = []

        let ref = TaskRef()
        ref.task = Task {
            for await device in service.scan() {
                discovered.append(device)
            }
        }
        await Task.yield()

        let id = UUID()
        service.handleDiscovery(id: id, name: "TestDevice", rssi: -55)
        service.stopScan()
        await ref.task?.value

        // 検出デバイスが1件ストリームに流れているはず
        #expect(discovered.count == 1)
        // 検出デバイスの id が一致しているはず
        #expect(discovered[0].id == id)
        // 検出デバイスの name が "TestDevice" であるはず
        #expect(discovered[0].name == "TestDevice")
        // 検出デバイスの rssi が -55 であるはず
        #expect(discovered[0].rssi == -55)
    }

    @Test("nameがnilの場合はUnknownになる")
    func discoveryWithNilNameUsesUnknown() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }
        var discovered: [ScannedDevice] = []

        let ref = TaskRef()
        ref.task = Task {
            for await device in service.scan() {
                discovered.append(device)
            }
        }
        await Task.yield()

        service.handleDiscovery(id: UUID(), name: nil, rssi: -70)
        service.stopScan()
        await ref.task?.value

        // name が nil のとき "Unknown" にフォールバックしているはず
        #expect(discovered[0].name == "Unknown")
    }

    // MARK: - 異常系

    @Test("poweredOff状態ではscanが呼ばれない")
    func poweredOffDoesNotScan() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }

        let ref = TaskRef()
        ref.task = Task { for await _ in service.scan() {} }
        await Task.yield()

        service.handleStateChange(.poweredOff)

        // poweredOff ではスキャンが開始されないはず
        #expect(!mock.scanCalled)
        service.stopScan()
        await ref.task?.value
    }

    @Test("unauthorized状態ではscanが呼ばれない")
    func unauthorizedDoesNotScan() async {
        let mock = MockScannerManaging()
        let service = BLEScannerService { _ in mock }

        let ref = TaskRef()
        ref.task = Task { for await _ in service.scan() {} }
        await Task.yield()

        service.handleStateChange(.unauthorized)

        // unauthorized ではスキャンが開始されないはず
        #expect(!mock.scanCalled)
        service.stopScan()
        await ref.task?.value
    }
}
