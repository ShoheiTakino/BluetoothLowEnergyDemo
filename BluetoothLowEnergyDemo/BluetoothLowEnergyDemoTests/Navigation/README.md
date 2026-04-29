# Navigation テスト戦略

## 対象ファイル
- `AppRouterTests.swift`

## テスト対象
`Core/Navigation/AppRouter`（NavigationPath のスタック管理）

## 戦略
`AppRouter` は `@Observable` の純粋なクラスで、View・BLE への依存がない。
インスタンスを直接生成して `path` の変化を検証する。

- モック不要
- 非同期処理なし
- `router.push()` / `router.pop()` / `router.popToRoot()` の状態遷移を検証

## テスト観点
| 観点 | 内容 |
|---|---|
| push | パスが積まれるか |
| pop | パスが1つ減るか |
| popToRoot | パスが空になるか |
| 境界値 | 空スタックで pop しても crash しないか |

## 注意
`NavigationPath` は内部表現が不透明なため、`path.count` で間接的に検証する。
