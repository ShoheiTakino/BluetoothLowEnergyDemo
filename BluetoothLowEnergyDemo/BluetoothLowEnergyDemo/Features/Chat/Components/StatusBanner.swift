import SwiftUI

/// チャット画面上部に表示する接続状態バナー。
///
/// Central / Peripheral でそれぞれ異なる状態管理をしているため、
/// `viewModel.mode` によって表示ロジックを分岐させている。
struct StatusBanner: View {
    let viewModel: ChatViewModel

    private var isConnected: Bool {
        switch viewModel.mode {
        case .central: return viewModel.connectionState == .ready
        case .peripheral: return viewModel.subscribedCentralCount > 0
        }
    }

    private var statusText: String {
        switch viewModel.mode {
        case .central:
            switch viewModel.connectionState {
            case .disconnected: return "スキャン中..."
            case .connecting: return "接続中..."
            case .ready: return "通信可能"
            }
        case .peripheral:
            return viewModel.subscribedCentralCount > 0 ? "Central が接続中" : "アドバタイズ中..."
        }
    }

    private var modeLabel: String {
        switch viewModel.mode {
        case .central: return "Central"
        case .peripheral: return "Peripheral"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(modeLabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.12))
    }
}
