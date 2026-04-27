import Foundation
import CoreBluetooth

private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
private let messageCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789013")

/// CoreBluetoothの実装。BLE状態（接続・Characteristic）を管理する。
/// イベントはBLEServiceDelegateを通じてPresentation層へ通知する。
final class BLEService: NSObject, BLEServiceProtocol {

    weak var delegate: (any BLEServiceDelegate)?

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var connectedPeripheral: CBPeripheral?
    private var messageCharacteristic: CBCharacteristic?
    private var transferCharacteristic: CBMutableCharacteristic?
    private var subscribedCentrals: [CBCentral] = []

    // MARK: - BLEServiceProtocol

    func startAsCentral() {
        centralManager = CBCentralManager(delegate: self, queue: .main)
        delegate?.bleServiceDidLog("Central モード開始")
    }

    func startAsPeripheral() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
        delegate?.bleServiceDidLog("Peripheral モード開始")
    }

    func stop() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        centralManager = nil
        peripheralManager = nil
        connectedPeripheral = nil
        messageCharacteristic = nil
        transferCharacteristic = nil
        subscribedCentrals = []
        delegate?.bleServiceDidLog("停止しました")
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
        delegate?.bleServiceDidLog("接続中: \(peripheral.name ?? "Unknown")...")
    }

    func sendMessage(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }

        if let peripheral = connectedPeripheral, let char = messageCharacteristic {
            peripheral.writeValue(data, for: char, type: .withResponse)
            delegate?.bleServiceDidLog("送信: \(text)")
            return true
        }

        if let char = transferCharacteristic, !subscribedCentrals.isEmpty {
            peripheralManager?.updateValue(data, for: char, onSubscribedCentrals: nil)
            delegate?.bleServiceDidLog("送信: \(text)")
            return true
        }

        delegate?.bleServiceDidLog("送信失敗: 接続相手がいません")
        return false
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            switch central.state {
            case .poweredOn:
                delegate?.bleServiceDidLog("Bluetooth ON - スキャン中...")
                central.scanForPeripherals(withServices: [serviceUUID], options: nil)
            case .poweredOff:
                delegate?.bleServiceDidLog("Bluetooth がオフです")
            case .unauthorized:
                delegate?.bleServiceDidLog("Bluetooth の使用が許可されていません")
            default:
                delegate?.bleServiceDidLog("Bluetooth 状態: \(central.state.rawValue)")
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
            delegate?.bleService(didDiscover: peripheral, rssi: RSSI.intValue)
            delegate?.bleServiceDidLog("発見: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            connectedPeripheral = peripheral
            peripheral.delegate = self
            peripheral.discoverServices([serviceUUID])
            central.stopScan()
            delegate?.bleServiceDidConnect(peripheral: peripheral)
            delegate?.bleServiceDidLog("接続完了: \(peripheral.name ?? "Unknown")")
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
            delegate?.bleServiceDidDisconnect()
            delegate?.bleServiceDidLog("切断されました。再スキャン中...")
            central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            delegate?.bleServiceDidLog("接続失敗: \(error?.localizedDescription ?? "不明")")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEService: CBPeripheralDelegate {
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
                delegate?.bleServiceDidBecomeReady()
                delegate?.bleServiceDidLog("通信準備完了！")
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
            delegate?.bleServiceDidReceive(message: text)
            delegate?.bleServiceDidLog("受信: \(text)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEService: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        MainActor.assumeIsolated {
            switch peripheral.state {
            case .poweredOn:
                delegate?.bleServiceDidLog("Bluetooth ON - サービス設定中...")
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
                delegate?.bleServiceDidLog("Bluetooth がオフです")
            case .unauthorized:
                delegate?.bleServiceDidLog("Bluetooth の使用が許可されていません")
            default:
                delegate?.bleServiceDidLog("Bluetooth 状態: \(peripheral.state.rawValue)")
            }
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            if let error = error {
                delegate?.bleServiceDidLog("サービスエラー: \(error.localizedDescription)")
                return
            }
            peripheral.startAdvertising([
                CBAdvertisementDataLocalNameKey: "BLEDemo",
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
            ])
            delegate?.bleServiceDidLog("アドバタイズ中 (BLEDemo)...")
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        MainActor.assumeIsolated {
            for req in requests where req.characteristic.uuid == messageCharUUID {
                if let data = req.value, let text = String(data: data, encoding: .utf8) {
                    delegate?.bleServiceDidReceive(message: text)
                    delegate?.bleServiceDidLog("受信: \(text)")
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
            delegate?.bleServiceCentralCountChanged(subscribedCentrals.count)
            delegate?.bleServiceDidLog("Central が接続しました")
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        MainActor.assumeIsolated {
            subscribedCentrals.removeAll { $0 == central }
            delegate?.bleServiceCentralCountChanged(subscribedCentrals.count)
            delegate?.bleServiceDidLog("Central が切断しました")
        }
    }
}
