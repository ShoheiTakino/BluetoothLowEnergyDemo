import Foundation

/// アプリ全体の依存関係コンテナ。
///
/// サービスの生成責務をこの1クラスに集約することで、
/// ViewModel はプロトコル越しにサービスを受け取り、具体型に依存しない。
/// テスト・Preview では `live` の代わりに Mock を注入するだけで差し替えられる。
///
/// `chatSessionFactory` はチャット画面を開くたびに新しいセッションを生成する。
/// チャットは「接続〜切断」を1セッションとして管理するため、
/// 画面遷移ごとに状態をリセットする目的でファクトリ形式を採用している。
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

    /// 本番用の依存セット。アプリ起動時に1度だけ生成される。
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
