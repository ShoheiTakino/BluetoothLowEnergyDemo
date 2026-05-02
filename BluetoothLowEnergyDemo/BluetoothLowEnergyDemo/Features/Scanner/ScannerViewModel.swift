import Foundation
import Observation

/// BLE スキャナー画面の状態管理。
@Observable
@MainActor
final class ScannerViewModel {
    private(set) var devices: [ScannedDevice] = []
    private(set) var isScanning = false

    private let service: any BLEScannerServiceProtocol
    private let runTask: TaskRunner
    private var scanTask: Task<Void, Never>?

    init(
        service: any BLEScannerServiceProtocol,
        runTask: @escaping TaskRunner = { operation in Task { await operation() } }
    ) {
        self.service = service
        self.runTask = runTask
    }

    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        devices = []
        scanTask = runTask { [weak self] in
            guard let self else { return }
            for await device in service.scan() {
                // 同一デバイスが再発見されたときは RSSI を最新値に更新する（重複追加しない）。
                if let index = devices.firstIndex(where: { $0.id == device.id }) {
                    devices[index] = device
                } else {
                    devices.append(device)
                }
            }
            isScanning = false
        }
    }

    func stopScan() {
        service.stopScan()
        scanTask?.cancel()
        isScanning = false
    }

    func onDisappear() {
        stopScan()
    }
}
