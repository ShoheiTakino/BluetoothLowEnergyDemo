import Foundation

/// BLE スキャン機能を提供するサービスのインターフェース。
///
/// `scan()` は `AsyncStream<ScannedDevice>` を返し、
/// デバイスが発見されるたびに値を流す。`stopScan()` でストリームが終了する。
/// `Sendable` 適合により、MainActor 境界を越えた注入が安全に行える。
protocol BLEScannerServiceProtocol: AnyObject, Sendable {
    /// BLE スキャンを開始し、発見されたデバイスを順次流す AsyncStream を返す。
    /// `stopScan()` が呼ばれるとストリームが finish する。
    func scan() -> AsyncStream<ScannedDevice>

    /// スキャンを停止し、`scan()` で返したストリームを終了させる。
    func stopScan()
}
