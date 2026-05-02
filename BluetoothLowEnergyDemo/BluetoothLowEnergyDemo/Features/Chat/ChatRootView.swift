import SwiftUI

/// チャットのモード選択画面。Central / Peripheral のどちらとして動作するかを選択する。
///
/// モードの決定責務をこの画面に持たせることで、`ChatView` は渡されたモードで動作するだけでよい。
struct ChatRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "message.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("モードを選択")
                    .font(.title2.bold())
                Text("2台のiPhoneをBLEで接続します")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                ModeButton(
                    title: "Central（スキャン側）",
                    subtitle: "周辺デバイスを検索して接続する",
                    icon: "magnifyingglass.circle.fill",
                    color: .blue
                ) {
                    router.push(.chatSession(.central))
                }

                ModeButton(
                    title: "Peripheral（アドバタイズ側）",
                    subtitle: "存在を知らせてCentralからの接続を待つ",
                    icon: "antenna.radiowaves.left.and.right.circle.fill",
                    color: .green
                ) {
                    router.push(.chatSession(.peripheral))
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("BLE チャット")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// ChatRootView のみで使用するため private で定義する。
private struct ModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(color)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
