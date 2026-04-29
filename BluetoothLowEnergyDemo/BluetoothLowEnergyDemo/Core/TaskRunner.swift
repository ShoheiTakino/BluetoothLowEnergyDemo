import Foundation

/// Task生成をテストで差し替えるための型エイリアス。
/// デフォルトは `Task { await operation() }` を使い、
/// テストではキャプチャした Task を `await task.value` で待つ。
typealias TaskRunner = @MainActor (_ operation: @escaping @MainActor () async -> Void) -> Task<Void, Never>
