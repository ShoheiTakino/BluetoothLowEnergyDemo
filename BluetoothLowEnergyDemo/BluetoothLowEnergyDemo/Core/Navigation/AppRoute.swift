import Foundation

enum AppRoute: Hashable {
    case scanner
    case chat
    case chatSession(BLEChatMode)
}
