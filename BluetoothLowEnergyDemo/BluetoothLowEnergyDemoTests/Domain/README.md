# Domain テスト戦略

## 対象ファイル
- `DomainTests.swift`

## テスト対象
`Core/Domain/` 配下のモデル層（`BLEMessage`・`ScannedDevice` など）

## 戦略
Domain 層は CoreBluetooth や非同期処理への依存がなく、純粋な値型（struct）のロジックのみを検証する。

- モック・スタブは不要
- 非同期処理なし（`async` 不使用）
- Swift Testing の `#expect` で値の等値性・初期値を直接検証

## テスト観点
| 観点 | 内容 |
|---|---|
| 初期値 | デフォルト引数の値が期待通りか |
| 不変性 | `let` プロパティが変更されないか |
| ファクトリ | カスタム引数を渡したときの値が正しいか |

## 注意
Domain 層のテストが壊れた場合、モデルの構造変更がある。ViewModel・Service 層への波及を先に確認すること。
