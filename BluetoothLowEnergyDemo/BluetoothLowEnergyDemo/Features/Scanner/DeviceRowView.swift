import SwiftUI

struct DeviceRowView: View {
    let device: ScannedDevice

    private var rssiColor: Color {
        if device.rssi >= -50 { return .green }
        if device.rssi >= -70 { return .orange }
        return .red
    }

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
