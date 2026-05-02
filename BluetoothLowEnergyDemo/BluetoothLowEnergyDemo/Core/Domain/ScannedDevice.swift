import Foundation

/// BLE スキャンで発見されたデバイスを表す値型。
///
/// CoreBluetooth の `CBPeripheral`（参照型・非 Sendable）をラップせず、
/// 必要な情報のみを抽出した Sendable な値型として定義する。
/// `CBPeripheral` の実体は `ChatCentralBridge` の peripheralCache で管理し、
/// UUID をキーとして引き当てる。
struct ScannedDevice: Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let discoveredAt: Date
}
