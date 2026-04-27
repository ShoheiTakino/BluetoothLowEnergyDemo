import Foundation
import CoreBluetooth
import Observation

private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
private let messageCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789013")

enum BLEMode {
    case idle, central, peripheral
}

struct BLEMessage: Identifiable {
    let id = UUID()
    let text: String
    let isSent: Bool
    let timestamp = Date()
}

@Observable
@MainActor
final class BLEManager: NSObject {
    var mode: BLEMode = .idle
    var logs: [String] = []
    var messages: [BLEMessage] = []
    var discoveredPeripherals: [CBPeripheral] = []
    var connectedPeripheral: CBPeripheral?
    var subscribedCentralCount: Int = 0
    var isReadyToSend: Bool = false

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var messageCharacteristic: CBCharacteristic?
    private var transferCharacteristic: CBMutableCharacteristic?
    private var subscribedCentrals: [CBCentral] = []

    // MARK: - Public API

    func startAsCentral() {
        mode = .central
        centralManager = CBCentralManager(delegate: self, queue: .main)
        log("Central モード開始")
    }

    func startAsPeripheral() {
        mode = .peripheral
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
        log("Peripheral モード開始")
    }

    func stopAll() {
        centralManager?.stopScan()
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        peripheralManager?.stopAdvertising()
        centralManager = nil
        peripheralManager = nil
        connectedPeripheral = nil
        discoveredPeripherals = []
        messageCharacteristic = nil
        transferCharacteristic = nil
        subscribedCentrals = []
        subscribedCentralCount = 0
        isReadyToSend = false
        mode = .idle
        log("停止しました")
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
        log("接続中: \(peripheral.name ?? "Unknown")...")
    }

    func sendMessage(_ text: String) {
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return }
        switch mode {
        case .central:
            guard let peripheral = connectedPeripheral,
                  let characteristic = messageCharacteristic else { return }
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            addMessage(text, isSent: true)
            log("送信: \(text)")
        case .peripheral:
            guard let characteristic = transferCharacteristic,
                  !subscribedCentrals.isEmpty else {
                log("接続中のCentralがいません")
                return
            }
            peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
            addMessage(text, isSent: true)
            log("送信: \(text)")
        case .idle:
            break
        }
    }

    // MARK: - Private helpers

    private func addMessage(_ text: String, isSent: Bool) {
        messages.append(BLEMessage(text: text, isSent: isSent))
    }

    private func log(_ text: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(time)] \(text)")
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            switch central.state {
            case .poweredOn:
                log("Bluetooth ON - スキャン中...")
                central.scanForPeripherals(withServices: [serviceUUID], options: nil)
            case .poweredOff:
                log("Bluetooth がオフです")
            case .unauthorized:
                log("Bluetooth の使用が許可されていません")
            default:
                log("Bluetooth 状態: \(central.state.rawValue)")
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        MainActor.assumeIsolated {
            guard !discoveredPeripherals.contains(peripheral) else { return }
            discoveredPeripherals.append(peripheral)
            log("発見: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            connectedPeripheral = peripheral
            peripheral.delegate = self
            peripheral.discoverServices([serviceUUID])
            central.stopScan()
            log("接続完了: \(peripheral.name ?? "Unknown")")
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            connectedPeripheral = nil
            messageCharacteristic = nil
            isReadyToSend = false
            log("切断されました。再スキャン中...")
            central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            log("接続失敗: \(error?.localizedDescription ?? "不明")")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated {
            guard let services = peripheral.services else { return }
            for service in services {
                peripheral.discoverCharacteristics([messageCharUUID], for: service)
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
            for char in chars where char.uuid == messageCharUUID {
                messageCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
                isReadyToSend = true
                log("通信準備完了！")
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard let data = characteristic.value,
                  let text = String(data: data, encoding: .utf8) else { return }
            addMessage(text, isSent: false)
            log("受信: \(text)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEManager: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        MainActor.assumeIsolated {
            switch peripheral.state {
            case .poweredOn:
                log("Bluetooth ON - サービス設定中...")
                let char = CBMutableCharacteristic(
                    type: messageCharUUID,
                    properties: [.notify, .write, .writeWithoutResponse],
                    value: nil,
                    permissions: [.readable, .writeable]
                )
                transferCharacteristic = char
                let service = CBMutableService(type: serviceUUID, primary: true)
                service.characteristics = [char]
                peripheral.add(service)
            case .poweredOff:
                log("Bluetooth がオフです")
            case .unauthorized:
                log("Bluetooth の使用が許可されていません")
            default:
                log("Bluetooth 状態: \(peripheral.state.rawValue)")
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        MainActor.assumeIsolated {
            if let error = error {
                log("サービスエラー: \(error.localizedDescription)")
                return
            }
            peripheral.startAdvertising([
                CBAdvertisementDataLocalNameKey: "BLEDemo",
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
            ])
            log("アドバタイズ中 (BLEDemo)...")
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        MainActor.assumeIsolated {
            for req in requests where req.characteristic.uuid == messageCharUUID {
                if let data = req.value, let text = String(data: data, encoding: .utf8) {
                    addMessage(text, isSent: false)
                    log("受信: \(text)")
                }
                peripheral.respond(to: req, withResult: .success)
            }
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        MainActor.assumeIsolated {
            subscribedCentrals.append(central)
            subscribedCentralCount = subscribedCentrals.count
            log("Central が接続しました")
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        MainActor.assumeIsolated {
            subscribedCentrals.removeAll { $0 == central }
            subscribedCentralCount = subscribedCentrals.count
            log("Central が切断しました")
        }
    }
}
