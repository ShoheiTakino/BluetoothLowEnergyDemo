import SwiftUI

/// スキャン結果リストの1行を表示するコンポーネント。
struct DeviceRowView: View {
    let device: ScannedDevice

    /// RSSI の強度に応じて色を変える。
    /// -50dBm 以上: 強い（緑）、-70dBm 以上: 普通（オレンジ）、それ以下: 弱い（赤）
    private var rssiColor: Color {
        if device.rssi >= -50 { return .green }
        if device.rssi >= -70 { return .orange }
        return .red
    }

    /// RSSI が -70dBm 以上のときは接続可能と判断しアイコンを変える。
    private var rssiIcon: String {
        if device.rssi >= -70 { return "wifi" }
        return "wifi.slash"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                // UUID の先頭8文字のみ表示してデバイスの一意性を視覚的に確認できるようにする。
                Text(device.id.uuidString.prefix(8) + "...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: rssiIcon)
                    .foregroundStyle(rssiColor)
                    .font(.caption)
                Text("\(device.rssi) dBm")
                    .font(.caption2)
                    .foregroundStyle(rssiColor)
            }
        }
        .padding(.vertical, 4)
    }
}
