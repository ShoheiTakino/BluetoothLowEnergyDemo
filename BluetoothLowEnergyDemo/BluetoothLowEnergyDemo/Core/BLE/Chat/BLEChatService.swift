import CoreBluetooth
import Foundation

// MARK: - BLECentralChatService

final class BLECentralChatService: NSObject, BLECentralSessionProtocol {
    private let centralBridge = ChatCentralBridge()
    private var centralManager: (any ChatCentralManaging)?
    private var messageCharacteristic: CBCharacteristic?
    private var connectedPeripheral: CBPeripheral?
    private var continuation: AsyncStream<BLEChatEvent>.Continuation?

    typealias CentralFactory = (CBCentralManagerDelegate) -> any ChatCentralManaging

    private let centralFactory: CentralFactory

    init(centralFactory: @escaping CentralFactory = { delegate in
        CBCentralManager(delegate: delegate, queue: .main)
    }) {
        self.centralFactory = centralFactory
        super.init()
        centralBridge.handler = self
    }

    func events() -> AsyncStream<BLEChatEvent> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }

    func start() {
        centralManager = centralFactory(centralBridge)
        emit(.log("Central モード開始"))
    }

    func connect(to deviceID: UUID) {
        guard let peripheral = centralBridge.peripheral(for: deviceID) else { return }
        centralManager?.connect(peripheral, options: nil)
        emit(.log("接続中: \(peripheral.name ?? "Unknown")..."))
    }

    func sendMessage(_ text: String) async throws {
        guard let data = text.data(using: .utf8) else { return }
        guard let peripheral = connectedPeripheral, let char = messageCharacteristic else {
            emit(.log("送信失敗: 接続相手がいません"))
            throw BLEChatError.notConnected
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        emit(.log("送信: \(text)"))
    }

    func stop() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        centralManager?.stopScan()
        centralManager = nil
        connectedPeripheral = nil
        messageCharacteristic = nil
        continuation?.finish()
        continuation = nil
    }

    private func emit(_ event: BLEChatEvent) {
        continuation?.yield(event)
    }
}

// MARK: - ChatCentralEventHandling

extension BLECentralChatService: ChatCentralEventHandling {
    func chatCentralDidUpdateState(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            emit(.log("Bluetooth ON - スキャン中..."))
            centralManager?.scanForPeripherals(withServices: [BLEConstants.serviceUUID], options: nil)
        case .poweredOff:
            emit(.log("Bluetooth がオフです"))
        case .unauthorized:
            emit(.log("Bluetooth の使用が許可されていません"))
        default:
            break
        }
    }

    func chatCentralDidDiscover(id: UUID, name: String?, rssi: Int) {
        let device = ScannedDevice(id: id, name: name ?? "Unknown", rssi: rssi, discoveredAt: Date())
        emit(.deviceDiscovered(device))
        emit(.log("発見: \(device.name) (RSSI: \(rssi))"))
    }

    func chatCentralDidConnect(peripheralId: UUID, peripheralName: String?) {
        guard let peripheral = centralBridge.peripheral(for: peripheralId) else { return }
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([BLEConstants.serviceUUID])
        centralManager?.stopScan()
        emit(.log("接続完了: \(peripheralName ?? "Unknown")"))
    }

    func chatCentralDidDisconnect(peripheralId: UUID, error: Error?) {
        connectedPeripheral = nil
        messageCharacteristic = nil
        emit(.disconnected)
        emit(.log("切断されました。再スキャン中..."))
        centralManager?.scanForPeripherals(withServices: [BLEConstants.serviceUUID], options: nil)
    }

    func chatCentralDidFailToConnect(peripheralId: UUID, error: Error?) {
        emit(.log("接続失敗: \(error?.localizedDescription ?? "不明")"))
    }
}

// MARK: - CBPeripheralDelegate（CBPeripheral具体型に依存するため抽象化対象外）

extension BLECentralChatService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated {
            guard let services = peripheral.services else { return }
            for service in services {
                peripheral.discoverCharacteristics([BLEConstants.messageCharUUID], for: service)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard let chars = service.characteristics else { return }
            for char in chars where char.uuid == BLEConstants.messageCharUUID {
                messageCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
                emit(.connected(deviceName: peripheral.name ?? "Unknown"))
                emit(.readyToSend)
                emit(.log("通信準備完了！"))
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard let data = characteristic.value else { return }
            if data == BLEConstants.disconnectSignal {
                centralManager?.cancelPeripheralConnection(peripheral)
                return
            }
            guard let text = String(data: data, encoding: .utf8) else { return }
            emit(.messageReceived(text))
            emit(.log("受信: \(text)"))
        }
    }
}

// MARK: - BLEPeripheralChatService

final class BLEPeripheralChatService: NSObject, BLEChatSessionProtocol {
    private let peripheralManagerBridge = ChatPeripheralManagerBridge()
    private var peripheralManager: (any ChatPeripheralManaging)?
    private var transferCharacteristic: CBMutableCharacteristic?
    private var subscribedCentralCount: Int = 0
    private var continuation: AsyncStream<BLEChatEvent>.Continuation?

    typealias PeripheralManagerFactory = (CBPeripheralManagerDelegate) -> any ChatPeripheralManaging

    private let peripheralManagerFactory: PeripheralManagerFactory

    init(peripheralManagerFactory: @escaping PeripheralManagerFactory = { delegate in
        CBPeripheralManager(delegate: delegate, queue: .main)
    }) {
        self.peripheralManagerFactory = peripheralManagerFactory
        super.init()
        peripheralManagerBridge.handler = self
    }

    func events() -> AsyncStream<BLEChatEvent> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }

    func start() {
        peripheralManager = peripheralManagerFactory(peripheralManagerBridge)
        emit(.log("Peripheral モード開始"))
    }

    func sendMessage(_ text: String) async throws {
        guard let data = text.data(using: .utf8) else { return }
        guard let char = transferCharacteristic, subscribedCentralCount > 0 else {
            emit(.log("送信失敗: 接続相手がいません"))
            throw BLEChatError.notConnected
        }
        _ = peripheralManager?.updateValue(data, for: char, onSubscribedCentrals: nil)
        emit(.log("送信: \(text)"))
    }

    func stop() {
        if let char = transferCharacteristic, subscribedCentralCount > 0 {
            _ = peripheralManager?.updateValue(BLEConstants.disconnectSignal, for: char, onSubscribedCentrals: nil)
        }
        peripheralManager?.stopAdvertising()
        peripheralManager = nil
        transferCharacteristic = nil
        subscribedCentralCount = 0
        continuation?.finish()
        continuation = nil
    }

    private func emit(_ event: BLEChatEvent) {
        continuation?.yield(event)
    }
}

// MARK: - ChatPeripheralManagerEventHandling

extension BLEPeripheralChatService: ChatPeripheralManagerEventHandling {
    func chatPeripheralManagerDidUpdateState(_ state: CBManagerState) {
        guard state == .poweredOn else { return }
        emit(.log("Bluetooth ON - サービス設定中..."))
        let char = CBMutableCharacteristic(
            type: BLEConstants.messageCharUUID,
            properties: [.notify, .write, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
        transferCharacteristic = char
        let service = CBMutableService(type: BLEConstants.serviceUUID, primary: true)
        service.characteristics = [char]
        peripheralManager?.add(service)
    }

    func chatPeripheralManagerDidAddService(error: Error?) {
        if let error {
            emit(.log("サービスエラー: \(error.localizedDescription)"))
            return
        }
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: BLEConstants.localName,
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.serviceUUID]
        ])
        emit(.log("アドバタイズ中 (\(BLEConstants.localName))..."))
    }

    func chatPeripheralManagerDidSubscribe() {
        subscribedCentralCount += 1
        emit(.centralCountChanged(subscribedCentralCount))
        emit(.log("Central が接続しました"))
    }

    func chatPeripheralManagerDidUnsubscribe() {
        subscribedCentralCount = max(0, subscribedCentralCount - 1)
        emit(.centralCountChanged(subscribedCentralCount))
        emit(.log("Central が切断しました"))
    }

    func chatPeripheralManagerDidReceiveMessage(_ text: String) {
        emit(.messageReceived(text))
        emit(.log("受信: \(text)"))
    }
}
