import Foundation

/// 非同期タスクの生成を抽象化するための型エイリアス。
///
/// ViewModel が `Task { await operation() }` を直接生成する代わりに、
/// このクロージャを通じて生成することで、テスト時に `Task` インスタンスを外部から補足できる。
///
/// ## テストでの使い方
/// ```swift
/// let ref = TaskRef()
/// let vm = ScannerViewModel(service: mock) { operation in
///     let task = Task { await operation() }
///     ref.task = task   // テスト側で Task を保持する
///     return task
/// }
/// vm.startScan()
/// await ref.task?.value  // ストリーム終了まで確実に待てる
/// ```
///
/// デフォルト実装（本番用）は単純に `Task { await operation() }` を返す。
typealias TaskRunner = @MainActor (_ operation: @escaping @MainActor () async -> Void) -> Task<Void, Never>
