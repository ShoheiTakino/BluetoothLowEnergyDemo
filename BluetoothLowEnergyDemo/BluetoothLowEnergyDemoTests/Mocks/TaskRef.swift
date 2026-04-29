import Foundation

final class TaskRef: @unchecked Sendable {
    var task: Task<Void, Never>?
}
