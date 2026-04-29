import SwiftUI

struct ChatView: View {
    @State var viewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            StatusBanner(viewModel: viewModel)

            if viewModel.mode == .central && viewModel.connectionState != .ready {
                PeripheralListView(viewModel: viewModel)
            }

            MessageListView(viewModel: viewModel)

            InputBar(viewModel: viewModel, inputText: $inputText, isInputFocused: $isInputFocused)
        }
        .navigationTitle(viewModel.mode == .central ? "Central" : "Peripheral")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("切断") {
                    viewModel.onDisappear()
                    router.pop()
                }
                .foregroundStyle(.red)
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .alert("送信失敗", isPresented: Binding(
            get: { viewModel.sendError != nil },
            set: { if !$0 { viewModel.clearSendError() } }
        )) {
            Button("OK") { viewModel.clearSendError() }
        } message: {
            Text("接続相手がいません")
        }
    }
}

private struct MessageListView: View {
    let viewModel: ChatViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if !viewModel.logs.isEmpty {
                        Divider().padding(.vertical, 8)
                        ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { index, log in
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
            .onChange(of: viewModel.logs.count) {
                if let lastIndex = viewModel.logs.indices.last {
                    withAnimation { proxy.scrollTo("log_\(lastIndex)", anchor: .bottom) }
                }
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
}
