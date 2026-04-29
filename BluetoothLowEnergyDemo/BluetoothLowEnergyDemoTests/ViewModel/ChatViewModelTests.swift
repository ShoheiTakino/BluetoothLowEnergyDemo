import Testing
import Foundation
@testable import BluetoothLowEnergyDemo

// MARK: - Helpers

@MainActor
private func makeCentralChat(
    mock: MockBLECentralSession
) -> (vm: ChatViewModel, ref: TaskRef) {
    let ref = TaskRef()
    let vm = ChatViewModel(session: .central(mock)) { operation in
        let task = Task { await operation() }
        ref.task = task
        return task
    }
    return (vm, ref)
}

@MainActor
private func makePeripheralChat(
    mock: MockBLEPeripheralSession
) -> (vm: ChatViewModel, ref: TaskRef) {
    let ref = TaskRef()
    let vm = ChatViewModel(session: .peripheral(mock)) { operation in
        let task = Task { await operation() }
        ref.task = task
        return task
    }
    return (vm, ref)
}

// MARK: - Suite

@Suite("ChatViewModel")
@MainActor
struct ChatViewModelTests {

    // MARK: - ライフサイクル

    @Test("onAppear時にCentralモードでstartが呼ばれる")
    func onAppearStartsCentral() {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))
        vm.onAppear()
        // Central セッションの start が呼ばれているはず
        #expect(mock.startCalled)
    }

    @Test("onAppear時にPeripheralモードでstartが呼ばれる")
    func onAppearStartsPeripheral() {
        let mock = MockBLEPeripheralSession()
        let vm = ChatViewModel(session: .peripheral(mock))
        vm.onAppear()
        // Peripheral セッションの start が呼ばれているはず
        #expect(mock.startCalled)
    }

    @Test("onDisappearでstopが呼ばれる")
    func onDisappearCallsStop() {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))
        vm.onDisappear()
        // セッションの stop が呼ばれているはず
        #expect(mock.stopCalled)
    }

    // MARK: - 正常系

    @Test("メッセージ受信でmessagesに追加される")
    func receiveMessageAddsToList() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.messageReceived("こんにちは"))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // messages に1件追加されているはず
        #expect(vm.messages.count == 1)
        // 受信テキストが "こんにちは" であるはず
        #expect(vm.messages[0].text == "こんにちは")
        // 受信メッセージなので isSent が false であるはず
        #expect(vm.messages[0].isSent == false)
    }

    @Test("sendMessageで有効なテキストがmessagesに追加される")
    func sendMessageAddsToMessages() async {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))

        await vm.sendMessage("Hello")

        // messages に1件追加されているはず
        #expect(vm.messages.count == 1)
        // 送信テキストが "Hello" であるはず
        #expect(vm.messages[0].text == "Hello")
        // 送信メッセージなので isSent が true であるはず
        #expect(vm.messages[0].isSent == true)
        // サービスにも "Hello" が渡されているはず
        #expect(mock.sentMessages == ["Hello"])
    }

    @Test("sendMessageで前後の空白がトリムされて送信される")
    func sendMessageTrimsWhitespace() async {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))

        await vm.sendMessage("  Hello  ")

        // サービスにはトリム済みの "Hello" が渡されているはず
        #expect(mock.sentMessages == ["Hello"])
        // messages に保存されるテキストもトリム済みであるはず
        #expect(vm.messages[0].text == "Hello")
    }

    @Test("connectでconnectionStateが.connectingになる")
    func connectSetsConnecting() {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))
        let device = ScannedDevice(id: UUID(), name: "iPhone", rssi: -60, discoveredAt: .now)

        vm.connect(to: device)

        // connectionState が .connecting に遷移しているはず
        #expect(vm.connectionState == .connecting)
        // サービスに接続対象の device.id が渡されているはず
        #expect(mock.connectedDeviceID == device.id)
    }

    @Test("readyToSendイベントでcanSendがtrueになる（Central）")
    func centralReadyToSendEnablesSend() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        // readyToSend 受信前は canSend が false であるはず
        #expect(vm.canSend == false)

        mock.eventsContinuation?.yield(.connected(deviceName: "iPhone"))
        mock.eventsContinuation?.yield(.readyToSend)
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // readyToSend 受信後は canSend が true になっているはず
        #expect(vm.canSend == true)
    }

    @Test("centralCountChanged > 0でcanSendがtrueになる（Peripheral）")
    func peripheralConnectedEnablesSend() async {
        let mock = MockBLEPeripheralSession()
        let (vm, ref) = makePeripheralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        // Central 未接続時は canSend が false であるはず
        #expect(vm.canSend == false)

        mock.eventsContinuation?.yield(.centralCountChanged(1))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // Central が1台接続されたので canSend が true になっているはず
        #expect(vm.canSend == true)
    }

    @Test("deviceDiscoveredイベントでdiscoveredDevicesに追加される")
    func deviceDiscoveredAddsToList() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)
        let device = ScannedDevice(id: UUID(), name: "iPhone", rssi: -60, discoveredAt: .now)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.deviceDiscovered(device))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // discoveredDevices に1件追加されているはず
        #expect(vm.discoveredDevices.count == 1)
        // 追加されたデバイスの id が一致しているはず
        #expect(vm.discoveredDevices[0].id == device.id)
    }

    @Test("disconnectedイベントでstateとdevicesがリセットされる")
    func disconnectedResetsState() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)
        let device = ScannedDevice(id: UUID(), name: "iPhone", rssi: -60, discoveredAt: .now)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.deviceDiscovered(device))
        mock.eventsContinuation?.yield(.disconnected)
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // 切断後は connectionState が .disconnected に戻っているはず
        #expect(vm.connectionState == .disconnected)
        // 切断後は discoveredDevices がクリアされているはず
        #expect(vm.discoveredDevices.isEmpty)
    }

    @Test("connectedイベントでlogsにデバイス名が記録される")
    func connectedEventAppendsLog() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.connected(deviceName: "iPhone"))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // logs に1件追加されているはず
        #expect(vm.logs.count == 1)
        // ログにデバイス名 "iPhone" が含まれているはず
        #expect(vm.logs[0].contains("iPhone"))
    }

    @Test("logイベントでlogsにテキストが記録される")
    func logEventAppendsToLogs() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.log("テストログ"))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // logs に1件追加されているはず
        #expect(vm.logs.count == 1)
        // ログに "テストログ" が含まれているはず
        #expect(vm.logs[0].contains("テストログ"))
    }

    @Test("sendMessageが失敗するとsendErrorにエラーがセットされmessagesに追加されない")
    func sendMessageErrorSetsSendError() async {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))

        mock.shouldThrowOnSend = true
        await vm.sendMessage("Hello")

        // 送信失敗時は messages に追加されないはず
        #expect(vm.messages.isEmpty)
        // sendError に .notConnected がセットされているはず
        #expect(vm.sendError == .notConnected)
    }

    @Test("clearSendErrorでsendErrorがnilになる")
    func clearSendErrorNilsError() async {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))
        mock.shouldThrowOnSend = true

        await vm.sendMessage("Hello")
        // sendError がセットされているはず
        #expect(vm.sendError != nil)

        vm.clearSendError()
        // clearSendError 後は sendError が nil になっているはず
        #expect(vm.sendError == nil)
    }

    // MARK: - 異常系

    @Test("空白のみのメッセージは送信されない")
    func emptyMessageNotSent() async {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))

        await vm.sendMessage("   ")

        // 空白のみなのでサービスに渡されていないはず
        #expect(mock.sentMessages.isEmpty)
        // messages にも追加されていないはず
        #expect(vm.messages.isEmpty)
    }

    @Test("同じIDのデバイスはdiscoveredDevicesに重複追加されない")
    func deviceDiscoveredNoDuplicates() async {
        let mock = MockBLECentralSession()
        let (vm, ref) = makeCentralChat(mock: mock)
        let device = ScannedDevice(id: UUID(), name: "iPhone", rssi: -60, discoveredAt: .now)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.deviceDiscovered(device))
        mock.eventsContinuation?.yield(.deviceDiscovered(device))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // 同じデバイスを2回受け取っても1件しか登録されないはず
        #expect(vm.discoveredDevices.count == 1)
    }

    @Test("PeripheralのcanSendはcentralCount=0のときfalse")
    func peripheralCanSendFalseWhenNoSubscribers() async {
        let mock = MockBLEPeripheralSession()
        let (vm, ref) = makePeripheralChat(mock: mock)

        vm.onAppear()
        await Task.yield()
        mock.eventsContinuation?.yield(.centralCountChanged(0))
        mock.eventsContinuation?.finish()
        await ref.task?.value

        // 購読中の Central が0台なので canSend が false であるはず
        #expect(vm.canSend == false)
    }

    @Test("CentralのcanSendはreadyToSend前はfalse")
    func centralCanSendFalseBeforeReady() {
        let mock = MockBLECentralSession()
        let vm = ChatViewModel(session: .central(mock))
        // readyToSend イベント未受信なので canSend が false であるはず
        #expect(vm.canSend == false)
    }
}
