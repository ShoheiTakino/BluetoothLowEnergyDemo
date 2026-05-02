import CoreBluetooth
import Foundation

// MARK: - BLECentralChatService

/// Central として BLE チャットを行うサービス。
///
/// `CBCentralManager` は直接保持せず `ChatCentralManaging` プロトコル越しに操作する。
/// デリゲートは `ChatCentralBridge` に委譲し、`CBPeripheral` のキャッシュもブリッジが担う。
/// これにより、このクラスは `CBPeripheral` の実体を持たず UUID のみで管理できる。
final class BLECentralChatService: NSObject, BLECentralSessionProtocol {
    private let centralBridge = ChatCentralBridge()
    private var centralManager: (any ChatCentralManaging)?
    private var messageCharacteristic: CBCharacteristic?
    private var connectedPeripheral: CBPeripheral?
    private var continuation: AsyncStream<BLEChatEvent>.Continuation?

    typealias CentralFactory = (CBCentralManagerDelegate) -> any ChatCentralManaging

    private let centralFactory: CentralFactory

    init(centralFactory: @escaping CentralFactory = { delegate in
        // queue: .main を指定することで、デリゲートコールバックが常にメインスレッドで呼ばれる。
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
        // start() のタイミングで初期化することで、poweredOn になったときに chatCentralDidUpdateState 経由でスキャンが開始される。
        centralManager = centralFactory(centralBridge)
        emit(.log("Central モード開始"))
    }

    func connect(to deviceID: UUID) {
        // UUID からブリッジのキャッシュ経由で CBPeripheral を取得する。
        // didDiscover 時にブリッジがキャッシュしているため、ここでは nil になることは基本的にない。
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
        // withResponse を指定することで Peripheral 側の didReceiveWrite が呼ばれる。
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
        // ストリームを finish することで ViewModel の for await ループが終了する。
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

// MARK: - CBPeripheralDelegate

/// `CBPeripheralDelegate` は `CBPeripheral` / `CBService` / `CBCharacteristic` 等の
/// CoreBluetooth 具体型に直接依存するため、ブリッジによる抽象化の対象外とし、ここで直接実装する。
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
                // Notify を登録することで Peripheral からの通知を受け取れるようになる。
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
            // Peripheral の stop() 時に送信される 0xFF バイトで切断シグナルを検知し、
            // BLE スーパービジョンタイムアウト（最大約6秒）を待たずに即時切断する。
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

/// Peripheral として BLE チャットを行うサービス。
///
/// `CBPeripheralManager` を直接保持せず `ChatPeripheralManaging` プロトコル越しに操作する。
/// デリゲートはすべて `ChatPeripheralManagerBridge` に委譲する。
final class BLEPeripheralChatService: NSObject, BLEChatSessionProtocol {
    private let peripheralManagerBridge = ChatPeripheralManagerBridge()
    private var peripheralManager: (any ChatPeripheralManaging)?
    private var transferCharacteristic: CBMutableCharacteristic?
    /// 現在 Notify を購読中の Central 台数。0 のとき送信不可と判定する。
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
        // updateValue で Notify 購読中の全 Central にメッセージを送信する。
        _ = peripheralManager?.updateValue(data, for: char, onSubscribedCentrals: nil)
        emit(.log("送信: \(text)"))
    }

    func stop() {
        // 切断前に購読中の Central へ切断シグナルを送信する。
        // これにより Central 側がスーパービジョンタイムアウト（最大約6秒）を待たずに即時切断を検知できる。
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
        // notify（Peripheral → Central）と write（Central → Peripheral）の両方をサポートするキャラクタリスティックを作成する。
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
        // 購読数が負にならないよう max(0, ...) でガードする。
        subscribedCentralCount = max(0, subscribedCentralCount - 1)
        emit(.centralCountChanged(subscribedCentralCount))
        emit(.log("Central が切断しました"))
    }

    func chatPeripheralManagerDidReceiveMessage(_ text: String) {
        emit(.messageReceived(text))
        emit(.log("受信: \(text)"))
    }
}
