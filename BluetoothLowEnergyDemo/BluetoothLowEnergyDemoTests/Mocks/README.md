# Mocks

## ファイル一覧

| ファイル | 用途 |
|---|---|
| `MockBLEScannerService.swift` | `BLEScannerServiceProtocol` の Mock。`stubbedDevices` を AsyncStream で流す |
| `MockBLEChatService.swift` | `BLECentralSessionProtocol` / `BLEPeripheralSessionProtocol` の Mock。`eventsContinuation` で外部からイベントを注入できる |
| `MockScannerManaging.swift` | `ScannerManaging` の Mock。`scanCalled` / `stopScanCalled` で操作の有無を記録する |
| `MockChatManaging.swift` | `ChatCentralManaging` / `ChatPeripheralManaging` の Mock。各操作の呼び出し有無を記録する |
| `TaskRef.swift` | 非同期テスト用ヘルパー。`Task` のインスタンスを外部から参照するための参照型ラッパー |

## Mock 設計方針

### @MainActor final class
Mock は `@MainActor final class` として定義することで `@unchecked Sendable` 不要にしている。
アクター分離により Sendable 適合が保証される。

### 外部注入パターン（MockBLEChatService）
```swift
// テスト側から continuation を操作してイベントを任意に発行
mock.eventsContinuation?.yield(.messageReceived("Hello"))
mock.eventsContinuation?.finish()
```

### フラグパターン（MockScannerManaging など）
```swift
// メソッドが呼ばれたかどうかを記録
#expect(mock.scanCalled)
#expect(mock.stopScanCalled)
```

## 注意
Mock はテストターゲット専用。本番コードからは参照しないこと。
