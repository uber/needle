//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Errors that can occur during a sequence execution.
enum SequenceExecutionError: Error {
    /// The waiting on sequence completion timed out.
    case awaitTimeout
}

/// The handle of the execution of a sequence of tasks, that allows control and
/// monitoring of the said sequence of tasks.
public protocol SequenceExecutionHandle {

    /// Block the caller thread until the sequence of tasks all finished execution
    /// or the specified timeout period has elapsed. The completion is achieved by
    /// a task returning `nil` after execution. This marks the said task the
    /// terminating task.
    ///
    /// - parameter timeout: The duration to wait before the timeout error is thrown.
    /// `nil` to wait forever until the sequence execution completes.
    /// - throws: `SequenceExecutionError.awaitTimeout` if the given timeout period
    /// elapsed before the sequence execution completed.
    func await(withTimeout timeout: TimeInterval?) throws

    /// Cancel the sequence execution at the point this function is invoked.
    func cancel()
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `SequencedTask`.
public protocol SequenceExecutor {

    /// Execute a sequence of tasks from the given task.
    ///
    /// - parameter task: The root task of the sequence of tasks to be executed.
    /// - returns: The execution handle that allows control and monitoring of the
    /// sequence of tasks being executed.
    func execute(sequenceFrom task: SequencedTask) -> SequenceExecutionHandle
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `SequencedTask`.
public class SequenceExecutorImpl: SequenceExecutor {

    /// Initializer.
    ///
    /// - parameter name: The name of the executor.
    public init(name: String, qos: DispatchQoS = .userInitiated) {
        taskQueue = DispatchQueue(label: "Executor.taskQueue-\(name)", qos: qos, attributes: .concurrent)
    }

    /// Execute a sequence of tasks from the given task.
    ///
    /// - parameter task: The root task of the sequence of tasks to be executed.
    /// - returns: The execution handle that allows control and monitoring of the
    /// sequence of tasks being executed.
    public func execute(sequenceFrom task: SequencedTask) -> SequenceExecutionHandle {
        let handle = SequenceExecutionHandleImpl()
        execute(task: task, withSequenceHandle: handle)
        return handle
    }

    // MARK: - Private

    private let taskQueue: DispatchQueue

    private func execute(task: SequencedTask, withSequenceHandle handle: SequenceExecutionHandleImpl) {
        taskQueue.async {
            guard !handle.isCancelled else {
                return
            }

            if let nextTask = task.execute() {
                self.execute(task: nextTask, withSequenceHandle: handle)
            } else {
                handle.sequenceDidComplete()
            }
        }
    }
}

private class SequenceExecutionHandleImpl: SequenceExecutionHandle {

    private let latch = CountDownLatch(count: 1)
    private let didCancel = AtomicBool(initialValue: false)

    fileprivate var isCancelled: Bool {
        return didCancel.value
    }

    fileprivate func await(withTimeout timeout: TimeInterval?) throws {
        let didComplete = latch.await(timeout: timeout)
        if !didComplete {
            throw SequenceExecutionError.awaitTimeout
        }
    }

    fileprivate func sequenceDidComplete() {
        latch.countDown()
    }

    fileprivate func cancel() {
        didCancel.compareAndSet(expect: false, newValue: true)
    }
}
