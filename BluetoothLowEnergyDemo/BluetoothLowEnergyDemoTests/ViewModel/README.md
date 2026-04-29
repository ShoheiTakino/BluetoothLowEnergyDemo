# ViewModel テスト戦略

## 対象ファイル
- `HomeViewModelTests.swift`
- `ScannerViewModelTests.swift`
- `ChatViewModelTests.swift`

## テスト対象
- `Features/Home/HomeViewModel`
- `Features/Scanner/ScannerViewModel`
- `Features/Chat/ChatViewModel`

## 戦略
ViewModel は BLE サービス層をプロトコル経由で受け取るため、Mock に差し替えて
CoreBluetooth なしで UI ロジックを検証する。

### 同期テスト
`HomeViewModel` など非同期処理のない ViewModel はインスタンス生成後に即検証。

```swift
let vm = HomeViewModel()
#expect(vm.features.count == 2)
```

### 非同期テスト（AsyncStream を使う ViewModel）
`TaskRunner` を注入して `Task` のインスタンスを `TaskRef` で補足し、
ストリームの完了を `await ref.task?.value` で待つ。

```swift
let ref = TaskRef()
let vm = ScannerViewModel(service: mock) { operation in
    let task = Task { await operation() }
    ref.task = task
    return task
}
vm.startScan()
await ref.task?.value
#expect(vm.devices.count == 2)
```

Mock の `eventsContinuation` を外部から `yield` / `finish` することで、
任意のタイミングでイベントを注入できる。

```swift
mock.eventsContinuation?.yield(.messageReceived("Hello"))
mock.eventsContinuation?.finish()
await ref.task?.value
```

## テスト観点
| 観点 | 内容 |
|---|---|
| ライフサイクル | onAppear で start、onDisappear で stop が呼ばれるか |
| 状態反映 | 各イベント受信後に @Observable プロパティが正しく更新されるか |
| 送信ロジック | 空白トリム・空文字スキップ・エラー伝播 |
| 重複排除 | 同一 ID のデバイスが重複登録されないか |
| 境界値 | canSend の true/false 切り替えタイミング |

## 使用モック
- `MockBLEScannerService` — stubbedDevices でスキャン結果を注入
- `MockBLECentralSession` — eventsContinuation でイベントを任意に発行、shouldThrowOnSend でエラー注入
- `MockBLEPeripheralSession` — 同上（Peripheral 側）

## 注意
ViewModel テストは UI（View）を生成しない。View のレイアウト・アニメーションは対象外。
