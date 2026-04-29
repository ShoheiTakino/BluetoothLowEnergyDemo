import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {

    enum Session {
        case central(any BLECentralSessionProtocol)
        case peripheral(any BLEPeripheralSessionProtocol)

        var mode: BLEChatMode {
            switch self {
            case .central: return .central
            case .peripheral: return .peripheral
            }
        }

        var underlying: any BLEChatSessionProtocol {
            switch self {
            case .central(let s): return s
            case .peripheral(let s): return s
            }
        }
    }

    private(set) var messages: [BLEMessage] = []
    private(set) var logs: [String] = []
    private(set) var connectionState: BLEConnectionState = .disconnected
    private(set) var discoveredDevices: [ScannedDevice] = []
    private(set) var subscribedCentralCount: Int = 0
    private(set) var sendError: BLEChatError?

    var mode: BLEChatMode { session.mode }

    var canSend: Bool {
        switch session {
        case .central: return connectionState == .ready
        case .peripheral: return subscribedCentralCount > 0
        }
    }

    private let session: Session
    private let runTask: TaskRunner
    private var eventTask: Task<Void, Never>?

    init(
        session: Session,
        runTask: @escaping TaskRunner = { operation in Task { await operation() } }
    ) {
        self.session = session
        self.runTask = runTask
    }

    func onAppear() {
        eventTask = runTask { [weak self] in
            guard let self else { return }
            for await event in session.underlying.events() {
                handle(event)
            }
        }
        session.underlying.start()
    }

    func onDisappear() {
        session.underlying.stop()
        eventTask?.cancel()
    }

    func connect(to device: ScannedDevice) {
        guard case .central(let svc) = session else { return }
        svc.connect(to: device.id)
        connectionState = .connecting
    }

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try await session.underlying.sendMessage(trimmed)
            messages.append(BLEMessage(text: trimmed, isSent: true))
        } catch let error as BLEChatError {
            sendError = error
        } catch {}
    }

    func clearSendError() {
        sendError = nil
    }

    private func handle(_ event: BLEChatEvent) {
        switch event {
        case .deviceDiscovered(let device):
            if !discoveredDevices.contains(where: { $0.id == device.id }) {
                discoveredDevices.append(device)
            }
        case .connected(let name):
            appendLog("接続完了: \(name)")
        case .disconnected:
            connectionState = .disconnected
            discoveredDevices = []
        case .readyToSend:
            connectionState = .ready
        case .centralCountChanged(let count):
            subscribedCentralCount = count
        case .messageReceived(let text):
            messages.append(BLEMessage(text: text, isSent: false))
        case .log(let text):
            appendLog(text)
        }
    }

    private func appendLog(_ text: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(time)] \(text)")
    }
}
