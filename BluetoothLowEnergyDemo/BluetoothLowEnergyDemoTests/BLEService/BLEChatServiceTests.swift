import Testing
import Foundation
import CoreBluetooth
@testable import BluetoothLowEnergyDemo

// MARK: - BLECentralChatService

@Suite("BLECentralChatService")
@MainActor
struct BLECentralChatServiceTests {

    // MARK: - sendMessage

    @Test("未接続時はnotConnectedエラーをthrowする")
    func throwsWhenNotConnected() async {
        let service = BLECentralChatService()

        // 未接続状態で sendMessage すると .notConnected がthrowされるはず
        await #expect(throws: BLEChatError.notConnected) {
            try await service.sendMessage("Hello")
        }
    }

    @Test("未接続時のsendMessageは送信失敗ログを流す")
    func emitsLogOnSendFailure() async {
        let service = BLECentralChatService()
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        try? await service.sendMessage("Hello")
        service.stop()
        await ref.task?.value

        // 送信失敗を示すログイベントが流れているはず
        #expect(events.contains { if case .log(let t) = $0 { return t.contains("送信失敗") }; return false })
    }

    // MARK: - stop

    @Test("stopを呼ぶとeventsストリームが終了する")
    func stopFinishesStream() async {
        let service = BLECentralChatService()
        var finished = false

        let ref = TaskRef()
        ref.task = Task {
            for await _ in service.events() {}
            finished = true
        }
        await Task.yield()

        service.stop()
        await ref.task?.value

        // stop 後にストリームが終端まで消費されているはず
        #expect(finished)
    }

    // MARK: - Central イベント

    @Test("poweredOnでスキャンが開始される")
    func poweredOnStartsScan() async {
        let mockCentral = MockChatCentralManaging()
        let service = BLECentralChatService(centralFactory: { _ in mockCentral })

        let ref = TaskRef()
        ref.task = Task { for await _ in service.events() {} }
        await Task.yield()

        service.start()
        service.chatCentralDidUpdateState(.poweredOn)

        // poweredOn でスキャンが開始されるはず
        #expect(mockCentral.scanCalled)
        service.stop()
        await ref.task?.value
    }

    @Test("poweredOffでスキャンが開始されない")
    func poweredOffDoesNotScan() async {
        let mockCentral = MockChatCentralManaging()
        let service = BLECentralChatService(centralFactory: { _ in mockCentral })

        let ref = TaskRef()
        ref.task = Task { for await _ in service.events() {} }
        await Task.yield()

        service.start()
        service.chatCentralDidUpdateState(.poweredOff)

        // poweredOff ではスキャンが開始されないはず
        #expect(!mockCentral.scanCalled)
        service.stop()
        await ref.task?.value
    }

    @Test("デバイス発見でdeviceDiscoveredイベントが流れる")
    func deviceDiscoveryEmitsEvent() async {
        let service = BLECentralChatService(centralFactory: { _ in MockChatCentralManaging() })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        let id = UUID()
        service.chatCentralDidDiscover(id: id, name: "iPhone", rssi: -60)
        service.stop()
        await ref.task?.value

        let discovered = events.compactMap { if case .deviceDiscovered(let d) = $0 { return d }; return nil }
        // deviceDiscovered イベントが1件流れているはず
        #expect(discovered.count == 1)
        // 発見デバイスの id が一致しているはず
        #expect(discovered[0].id == id)
        // 発見デバイスの name が "iPhone" であるはず
        #expect(discovered[0].name == "iPhone")
    }

    @Test("切断でdisconnectedイベントが流れ再スキャンが始まる")
    func disconnectEmitsEventAndRestartsScanning() async {
        let mockCentral = MockChatCentralManaging()
        let service = BLECentralChatService(centralFactory: { _ in mockCentral })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        service.start()
        service.chatCentralDidDisconnect(peripheralId: UUID(), error: nil)
        service.stop()
        await ref.task?.value

        // disconnected イベントが流れているはず
        #expect(events.contains { if case .disconnected = $0 { return true }; return false })
        // 切断後に再スキャンが始まっているはず
        #expect(mockCentral.scanCalled)
    }

    @Test("接続失敗でlogイベントが流れる")
    func failToConnectEmitsLog() async {
        let service = BLECentralChatService(centralFactory: { _ in MockChatCentralManaging() })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        service.chatCentralDidFailToConnect(peripheralId: UUID(), error: nil)
        service.stop()
        await ref.task?.value

        // 接続失敗を示す log イベントが流れているはず
        #expect(events.contains { if case .log = $0 { return true }; return false })
    }
}

// MARK: - BLEPeripheralChatService

@Suite("BLEPeripheralChatService")
@MainActor
struct BLEPeripheralChatServiceTests {

    // MARK: - sendMessage

    @Test("未接続時はnotConnectedエラーをthrowする")
    func throwsWhenNotConnected() async {
        let service = BLEPeripheralChatService()

        // 未接続状態で sendMessage すると .notConnected がthrowされるはず
        await #expect(throws: BLEChatError.notConnected) {
            try await service.sendMessage("Hello")
        }
    }

    @Test("未接続時のsendMessageは送信失敗ログを流す")
    func emitsLogOnSendFailure() async {
        let service = BLEPeripheralChatService()
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        try? await service.sendMessage("Hello")
        service.stop()
        await ref.task?.value

        // 送信失敗を示すログイベントが流れているはず
        #expect(events.contains { if case .log(let t) = $0 { return t.contains("送信失敗") }; return false })
    }

    // MARK: - stop

    @Test("stopを呼ぶとeventsストリームが終了する")
    func stopFinishesStream() async {
        let service = BLEPeripheralChatService()
        var finished = false

        let ref = TaskRef()
        ref.task = Task {
            for await _ in service.events() {}
            finished = true
        }
        await Task.yield()

        service.stop()
        await ref.task?.value

        // stop 後にストリームが終端まで消費されているはず
        #expect(finished)
    }

    // MARK: - PeripheralManager イベント

    @Test("poweredOnでサービスが追加される")
    func poweredOnAddsService() async {
        let mockPeripheral = MockChatPeripheralManaging()
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in mockPeripheral })

        let ref = TaskRef()
        ref.task = Task { for await _ in service.events() {} }
        await Task.yield()

        service.start()
        service.chatPeripheralManagerDidUpdateState(.poweredOn)

        // poweredOn で CBMutableService が追加されるはず
        #expect(mockPeripheral.addServiceCalled)
        service.stop()
        await ref.task?.value
    }

    @Test("サービス追加成功でアドバタイズが開始される")
    func serviceAddedStartsAdvertising() async {
        let mockPeripheral = MockChatPeripheralManaging()
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in mockPeripheral })

        let ref = TaskRef()
        ref.task = Task { for await _ in service.events() {} }
        await Task.yield()

        service.start()
        service.chatPeripheralManagerDidAddService(error: nil)

        // サービス追加成功後にアドバタイズが開始されるはず
        #expect(mockPeripheral.startAdvertisingCalled)
        service.stop()
        await ref.task?.value
    }

    @Test("サービス追加エラーでアドバタイズされずエラーログが流れる")
    func serviceAddErrorDoesNotAdvertise() async {
        let mockPeripheral = MockChatPeripheralManaging()
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in mockPeripheral })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        struct DummyError: Error {}
        service.chatPeripheralManagerDidAddService(error: DummyError())
        service.stop()
        await ref.task?.value

        // エラー時はアドバタイズが開始されないはず
        #expect(!mockPeripheral.startAdvertisingCalled)
        // "サービスエラー" を含むログイベントが流れているはず
        #expect(events.contains { if case .log(let t) = $0 { return t.contains("サービスエラー") }; return false })
    }

    @Test("Central購読でcentralCountChangedイベントが流れる")
    func subscribeEmitsCentralCountChanged() async {
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in MockChatPeripheralManaging() })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        service.chatPeripheralManagerDidSubscribe()
        service.chatPeripheralManagerDidSubscribe()
        service.stop()
        await ref.task?.value

        let counts = events.compactMap { if case .centralCountChanged(let c) = $0 { return c }; return nil }
        // 購読のたびにカウントが増え [1, 2] と流れているはず
        #expect(counts == [1, 2])
    }

    @Test("Central購読解除でcentralCountChangedイベントが流れる")
    func unsubscribeEmitsCentralCountChanged() async {
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in MockChatPeripheralManaging() })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        service.chatPeripheralManagerDidSubscribe()
        service.chatPeripheralManagerDidUnsubscribe()
        service.stop()
        await ref.task?.value

        let counts = events.compactMap { if case .centralCountChanged(let c) = $0 { return c }; return nil }
        // 購読→解除でカウントが [1, 0] と流れているはず
        #expect(counts == [1, 0])
    }

    @Test("購読数が0以下にはならない")
    func subscribedCountDoesNotGoBelowZero() async {
        let service = BLEPeripheralChatService(peripheralManagerFactory: { _ in MockChatPeripheralManaging() })
        var events: [BLEChatEvent] = []

        let ref = TaskRef()
        ref.task = Task {
            for await event in service.events() {
                events.append(event)
            }
        }
        await Task.yield()

        service.chatPeripheralManagerDidUnsubscribe()
        service.stop()
        await ref.task?.value

        let counts = events.compactMap { if case .centralCountChanged(let c) = $0 { return c }; return nil }
        // 購読数が負にならず全て 0 以上であるはず
        #expect(counts.allSatisfy { $0 >= 0 })
    }
}
