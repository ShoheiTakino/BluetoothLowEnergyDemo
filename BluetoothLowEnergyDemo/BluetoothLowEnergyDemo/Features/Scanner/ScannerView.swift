import SwiftUI

struct ScannerView: View {
    @State var viewModel: ScannerViewModel

    var body: some View {
        Group {
            if viewModel.devices.isEmpty && viewModel.isScanning {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("スキャン中...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "デバイスが見つかりません",
                    systemImage: "antenna.radiowaves.left.and.right.slash",
                    description: Text("スキャンを開始してください")
                )
            } else {
                List(viewModel.devices) { device in
                    DeviceRowView(device: device)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("BLE スキャナー")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isScanning ? viewModel.stopScan() : viewModel.startScan()
                } label: {
                    Text(viewModel.isScanning ? "停止" : "スキャン開始")
                }
            }
        }
        .onAppear { viewModel.startScan() }
        .onDisappear { viewModel.onDisappear() }
    }
}
