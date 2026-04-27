import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var ble = BLEManager()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if ble.mode == .idle {
                    ModeSelectionView(ble: ble)
                } else {
                    ChatView(ble: ble, inputText: $inputText, isInputFocused: $isInputFocused)
                }
            }
            .navigationTitle("BLE Demo")
        }
    }
}

// MARK: - Mode Selection

struct ModeSelectionView: View {
    let ble: BLEManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("モードを選択")
                    .font(.title2.bold())
                Text("2台のiPhoneをBLEで接続します")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                ModeButton(
                    title: "Central (スキャン側)",
                    subtitle: "周辺デバイスを検索して接続する",
                    icon: "magnifyingglass.circle.fill",
                    color: .blue
                ) {
                    ble.startAsCentral()
                }

                ModeButton(
                    title: "Peripheral (アドバタイズ側)",
                    subtitle: "存在を知らせてCentralからの接続を待つ",
                    icon: "antenna.radiowaves.left.and.right.circle.fill",
                    color: .green
                ) {
                    ble.startAsPeripheral()
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

struct ModeButton: View {
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

// MARK: - Chat View

struct ChatView: View {
    var ble: BLEManager
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            StatusBanner(ble: ble)

            if ble.mode == .central && ble.connectedPeripheral == nil {
                PeripheralListView(ble: ble)
            }

            MessageList(ble: ble)

            InputBar(ble: ble, inputText: $inputText, isInputFocused: $isInputFocused)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("停止", role: .destructive) {
                    ble.stopAll()
                }
                .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Status Banner

struct StatusBanner: View {
    var ble: BLEManager

    var statusText: String {
        switch ble.mode {
        case .central:
            if let name = ble.connectedPeripheral?.name {
                return "接続済み: \(name)"
            } else if !ble.discoveredPeripherals.isEmpty {
                return "デバイスが見つかりました"
            }
            return "スキャン中..."
        case .peripheral:
            return ble.subscribedCentralCount > 0 ? "Central が接続中" : "アドバタイズ中..."
        case .idle:
            return "待機中"
        }
    }

    var isConnected: Bool {
        switch ble.mode {
        case .central: ble.connectedPeripheral != nil
        case .peripheral: ble.subscribedCentralCount > 0
        case .idle: false
        }
    }

    var modeLabel: String {
        switch ble.mode {
        case .central: "Central"
        case .peripheral: "Peripheral"
        case .idle: ""
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? .green : .orange)
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

// MARK: - Peripheral List (Central only)

struct PeripheralListView: View {
    var ble: BLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("見つかったデバイス")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if ble.discoveredPeripherals.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("スキャン中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                ForEach(ble.discoveredPeripherals, id: \.identifier) { peripheral in
                    Button {
                        ble.connect(to: peripheral)
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(.blue)
                            Text(peripheral.name ?? "Unknown Device")
                                .foregroundStyle(.primary)
                            Spacer()
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
        .overlay(alignment: .bottom) {
            Divider()
        }
        .frame(maxHeight: 200)
    }
}

// MARK: - Message List

struct MessageList: View {
    var ble: BLEManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(ble.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if !ble.logs.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                        ForEach(Array(ble.logs.enumerated()), id: \.offset) { index, log in
                            HStack {
                                Text(log)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .id("log_\(index)")
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: ble.logs.count) {
                if let lastIndex = ble.logs.indices.last {
                    withAnimation {
                        proxy.scrollTo("log_\(lastIndex)", anchor: .bottom)
                    }
                }
            }
            .onChange(of: ble.messages.count) {
                if let last = ble.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: BLEMessage

    var body: some View {
        HStack {
            if message.isSent { Spacer() }

            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isSent ? Color.blue : Color(.systemGray5))
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

// MARK: - Input Bar

struct InputBar: View {
    var ble: BLEManager
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool

    var canSend: Bool {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch ble.mode {
        case .central: return ble.isReadyToSend
        case .peripheral: return ble.subscribedCentralCount > 0
        case .idle: return false
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("メッセージを入力...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(canSend ? .white : .secondary)
                    .frame(width: 40, height: 40)
                    .background(canSend ? Color.blue : Color.gray.opacity(0.2), in: Circle())
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.2), value: canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        ble.sendMessage(text)
        inputText = ""
    }
}

#Preview {
    ContentView()
}
