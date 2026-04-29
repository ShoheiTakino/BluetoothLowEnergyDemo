import SwiftUI

struct MessageBubble: View {
    let message: BLEMessage

    var body: some View {
        HStack {
            if message.isSent { Spacer() }

            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isSent ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.isSent ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isSent ? .trailing : .leading)

            if !message.isSent { Spacer() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
}
