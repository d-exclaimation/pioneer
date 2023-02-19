//
//  Task+Starvation.swift
//  pioneer
//
//  Created by d-exclaimation on 22:38.
//

public extension Task where Success == Never, Failure == Never {
    /// Postpone the current task and allows other tasks to execute.
    ///
    /// A task can voluntarily suspend itself in the middle of a long-running operation that doesn’t contain any suspension points, to let other tasks run for a while before execution returns to this task.
    ///
    /// This is a sister method to ``Task/yield()``, which is a suspension point that allows other tasks to run that forces the suspension of the current task and ignores the current task’s priority.
    static func postpone() async throws {
        try await Task.sleep(nanoseconds: 0)
    }
}
