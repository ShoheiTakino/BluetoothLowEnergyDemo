import SwiftUI

struct InputBar: View {
    let viewModel: ChatViewModel
    @Binding var inputText: String
    @FocusState.Binding var isInputFocused: Bool

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.canSend
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
        // テキストを先にキャプチャして inputText をクリアすることで、
        // 送信処理中に入力欄が空になり UX が向上する。
        let text = inputText
        inputText = ""
        Task { await viewModel.sendMessage(text) }
    }
}
