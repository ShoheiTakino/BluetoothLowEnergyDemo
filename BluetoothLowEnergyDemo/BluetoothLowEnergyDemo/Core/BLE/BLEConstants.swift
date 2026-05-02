import CoreBluetooth

/// BLE 通信で使用する定数群。
enum BLEConstants {
    /// チャットサービスを識別する UUID。Central はこの UUID を持つデバイスのみスキャン対象とする。
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")

    /// メッセージ送受信に使用するキャラクタリスティックの UUID。
    /// `.notify` + `.write` の両プロパティを持ち、双方向通信を実現する。
    static let messageCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789013")

    static let localName = "BLEDemo"

    /// Peripheral が切断意図を Central に通知するためのシグナル。
    ///
    /// `CBPeripheralManager` には「接続中の全 Central を切断する」APIが存在しないため、
    /// Peripheral の `stop()` 時にこのシグナルを notify で送信する。
    /// Central は受信後に `cancelPeripheralConnection` を呼び、
    /// スーパービジョンタイムアウト（最大約6秒）を待たずに即時切断を検知できる。
    static let disconnectSignal = Data([0xFF])
}
