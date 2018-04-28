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

/// The handle of the execution of a sequence of tasks, that allows control and
/// monitoring of the said sequence of tasks.
public protocol SequenceExecutionHandle {

    /// Block the caller thread until the sequence of tasks all finished execution.
    /// The completion is achieved by a task returning `nil` after execution. This
    /// marks the said task the terminating task.
    func await()

    /// Cancel the sequence execution at the point this function is invoked.
    func cancel()
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `SequencedTask`.
public class SequenceExecutor {

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

    fileprivate func await() {
        latch.await()
    }

    fileprivate func sequenceDidComplete() {
        latch.countDown()
    }

    fileprivate func cancel() {
        didCancel.compareAndSet(expect: false, newValue: true)
    }
}
