import Foundation

final class SingleFlightTask {
    private var runningTask: Task<Void, Never>?

    func run(_ operation: @escaping () async -> Void) async {
        if let runningTask {
            await runningTask.value
            return
        }
        let task = Task { await operation() }
        runningTask = task
        await task.value
        runningTask = nil
    }
}
