import SwiftUI

/// Central モードでスキャン中に発見されたデバイスを一覧表示し、タップで接続するコンポーネント。
///
/// `ChatView` で `connectionState != .ready` のときのみ表示される。
struct PeripheralListView: View {
    let viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("見つかったデバイス")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if viewModel.discoveredDevices.isEmpty {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("スキャン中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                ForEach(viewModel.discoveredDevices) { device in
                    Button {
                        viewModel.connect(to: device)
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(.blue)
                            Text(device.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(device.rssi) dBm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    Divider().padding(.leading, 44)
                }
            }
        }
        .background(Color(white: 1.0))
        .overlay(alignment: .bottom) { Divider() }
        // 最大高さを制限し、デバイスが多くてもメッセージエリアが確保されるようにする。
        .frame(maxHeight: 200)
    }
}
