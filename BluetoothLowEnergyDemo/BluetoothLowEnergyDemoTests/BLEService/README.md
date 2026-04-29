# BLEService テスト戦略

## 対象ファイル
- `BLEScannerServiceTests.swift`
- `BLEChatServiceTests.swift`

## テスト対象
- `Core/BLE/BLEScannerService`（スキャン制御）
- `Core/BLE/BLECentralChatService`（Central チャット制御）
- `Core/BLE/BLEPeripheralChatService`（Peripheral チャット制御）

## 戦略
CoreBluetooth の具体型（`CBCentralManager` / `CBPeripheralManager`）はテスト不可能なため、
`ChatCentralManaging` / `ChatPeripheralManaging` / `ScannerManaging` プロトコルを通じて
Mock に差し替えてサービス層のロジックを検証する。

```
テスト → Service → MockManaging（CBXxx の代替）
                ↑
         CBCentralBridge / CBPeripheralBridge が実機では仲介
```

AsyncStream のイベント受信は `TaskRef` + `await Task.yield()` パターンで決定論的に制御する。

```swift
let ref = TaskRef()
ref.task = Task { for await event in service.events() { ... } }
await Task.yield()   // ストリームの for await ループが開始されるまで待機

service.someCallback()  // イベントをトリガー
service.stop()
await ref.task?.value   // ストリームが終了するまで待機
```

## テスト観点
| 観点 | 内容 |
|---|---|
| ライフサイクル | stop() でストリームが終了するか |
| 状態遷移 | poweredOn / poweredOff で正しい操作が行われるか |
| イベント発行 | 各コールバックで正しいイベントが流れるか |
| エラー処理 | 未接続時の sendMessage が notConnected をthrowするか |
| 境界値 | 購読数が 0 以下にならないか、stopScan の冪等性など |

## 使用モック
- `MockScannerManaging` — スキャン操作の記録
- `MockChatCentralManaging` — Central 操作の記録
- `MockChatPeripheralManaging` — Peripheral 操作の記録

## 注意
実際の BLE 通信（デバイス発見・接続・メッセージ送受信）はこの層ではテストしない。
E2E 的な動作確認は実機での手動テストで行う。
