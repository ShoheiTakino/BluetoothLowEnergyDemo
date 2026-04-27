import Foundation
import CoreBluetooth
import Observation

/// 画面状態を管理するViewModel。
/// BLEServiceProtocolに依存し、CoreBluetoothの詳細を知らない。
@Observable
@MainActor
final class BLEViewModel {

    // MARK: - Published State (Viewが監視)

    var mode: BLEMode = .idle
    var messages: [BLEMessage] = []
    var logs: [String] = []
    var discoveredPeripherals: [CBPeripheral] = []
    var connectedPeripheral: CBPeripheral?
    var subscribedCentralCount: Int = 0
    var isReadyToSend: Bool = false

    /// 送信ボタンの活性状態（BLEの接続状況に依存する表示ロジック）
    var canSend: Bool {
        switch mode {
        case .central: return isReadyToSend
        case .peripheral: return subscribedCentralCount > 0
        case .idle: return false
        }
    }

    // MARK: - Private

    private let service: any BLEServiceProtocol

    // MARK: - Init

    init(service: any BLEServiceProtocol = BLEService()) {
        self.service = service
        self.service.delegate = self
    }

    // MARK: - Intents (Viewからのアクション)

    func startAsCentral() {
        mode = .central
        service.startAsCentral()
    }

    func startAsPeripheral() {
        mode = .peripheral
        service.startAsPeripheral()
    }

    func stopAll() {
        service.stop()
        mode = .idle
        discoveredPeripherals = []
        connectedPeripheral = nil
        subscribedCentralCount = 0
        isReadyToSend = false
    }

    func connect(to peripheral: CBPeripheral) {
        service.connect(to: peripheral)
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if service.sendMessage(trimmed) {
            addMessage(trimmed, isSent: true)
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

// MARK: - BLEServiceDelegate

extension BLEViewModel: BLEServiceDelegate {
    func bleService(didDiscover peripheral: CBPeripheral, rssi: Int) {
        guard !discoveredPeripherals.contains(peripheral) else { return }
        discoveredPeripherals.append(peripheral)
    }

    func bleServiceDidConnect(peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
    }

    func bleServiceDidDisconnect() {
        connectedPeripheral = nil
        isReadyToSend = false
    }

    func bleServiceDidBecomeReady() {
        isReadyToSend = true
    }

    func bleServiceCentralCountChanged(_ count: Int) {
        subscribedCentralCount = count
    }

    func bleServiceDidReceive(message: String) {
        addMessage(message, isSent: false)
    }

    func bleServiceDidLog(_ message: String) {
        log(message)
    }
}
