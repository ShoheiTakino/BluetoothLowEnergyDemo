import Testing
import Foundation
@testable import BluetoothLowEnergyDemo

@Suite("Domain")
@MainActor
struct DomainTests {

    // MARK: - BLEMessage

    @Test("送信メッセージが正しく生成される")
    func sentMessageInitialization() {
        let msg = BLEMessage(text: "Hello", isSent: true)
        // text に "Hello" が設定されているはず
        #expect(msg.text == "Hello")
        // isSent が true になっているはず
        #expect(msg.isSent == true)
    }

    @Test("受信メッセージが正しく生成される")
    func receivedMessageInitialization() {
        let msg = BLEMessage(text: "こんにちは", isSent: false)
        // text に "こんにちは" が設定されているはず
        #expect(msg.text == "こんにちは")
        // isSent が false になっているはず
        #expect(msg.isSent == false)
    }

    @Test("各メッセージはユニークなIDを持つ")
    func uniqueIDs() {
        let msg1 = BLEMessage(text: "A", isSent: true)
        let msg2 = BLEMessage(text: "A", isSent: true)
        // 同じ引数でも別インスタンスなので id は異なるはず
        #expect(msg1.id != msg2.id)
    }

    @Test("timestampが生成時刻に近い")
    func timestampIsRecent() {
        let before = Date()
        let msg = BLEMessage(text: "test", isSent: false)
        let after = Date()
        // timestamp は生成前の時刻以降であるはず
        #expect(msg.timestamp >= before)
        // timestamp は生成後の時刻以前であるはず
        #expect(msg.timestamp <= after)
    }

    @Test("idをinjectできる")
    func injectableID() {
        let fixedID = UUID()
        let msg = BLEMessage(text: "test", isSent: true, id: fixedID)
        // inject した UUID がそのまま id に設定されているはず
        #expect(msg.id == fixedID)
    }

    @Test("timestampをinjectできる")
    func injectableTimestamp() {
        let fixedDate = Date(timeIntervalSinceReferenceDate: 0)
        let msg = BLEMessage(text: "test", isSent: false, timestamp: fixedDate)
        // inject した Date がそのまま timestamp に設定されているはず
        #expect(msg.timestamp == fixedDate)
    }

}
