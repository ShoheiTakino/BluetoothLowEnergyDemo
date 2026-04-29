import Foundation

final class AppEnvironment {
    let scannerService: any BLEScannerServiceProtocol
    let chatSessionFactory: @Sendable (BLEChatMode) -> ChatViewModel.Session

    init(
        scannerService: any BLEScannerServiceProtocol,
        chatSessionFactory: @Sendable @escaping (BLEChatMode) -> ChatViewModel.Session
    ) {
        self.scannerService = scannerService
        self.chatSessionFactory = chatSessionFactory
    }

    static let live = AppEnvironment(
        scannerService: BLEScannerService(),
        chatSessionFactory: { mode in
            switch mode {
            case .central: return .central(BLECentralChatService())
            case .peripheral: return .peripheral(BLEPeripheralChatService())
            }
        }
    )
}
