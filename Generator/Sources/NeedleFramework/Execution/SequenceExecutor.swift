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

import Concurrency
import Foundation

/// Errors that can occur during a sequence execution.
enum SequenceExecutionError: Error {
    /// The waiting on sequence completion timed out.
    case awaitTimeout
}

/// The handle of the execution of a sequence of tasks, that allows control and
/// monitoring of the said sequence of tasks.
// This cannot be a protocol, since `SequenceExecutor` references this as a type.
// Protocols with associatedType cannot be directly used as types.
class SequenceExecutionHandle<SequenceResultType> {

    /// Block the caller thread until the sequence of tasks all finished execution
    /// or the specified timeout period has elapsed. The completion is achieved by
    /// a task returning `nil` after execution. This marks the said task the
    /// terminating task.
    ///
    /// - parameter timeout: The duration to wait before the timeout error is thrown.
    /// `nil` to wait forever until the sequence execution completes.
    /// - throws: `SequenceExecutionError.awaitTimeout` if the given timeout period
    /// elapsed before the sequence execution completed.
    func await(withTimeout timeout: TimeInterval?) throws -> SequenceResultType {
        fatalError("await not yet implemented.")
    }

    /// Cancel the sequence execution at the point this function is invoked.
    func cancel() {}
}

/// The execution of a sequence.
enum SequenceExecution<ResultType> {
    /// The execution of the sequence should continue with another task.
    case continueSequence(Task)
    /// The end of the entire task sequence with produced result.
    case endOfSequence(ResultType)
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `Task`.
protocol SequenceExecutor {

    /// Execute a sequence of tasks from the given initial task.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result. This closure is invoked from
    /// multiple threads concurrently.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType>
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `SequencedTask`.
class SequenceExecutorImpl: SequenceExecutor {

    /// Initializer.
    ///
    /// - parameter name: The name of the executor.
    init(name: String, qos: DispatchQoS = .userInitiated) {
        taskQueue = DispatchQueue(label: "Executor.taskQueue-\(name)", qos: qos, attributes: .concurrent)
    }

    /// Execute a sequence of tasks from the given initial task.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result. This closure is invoked from
    /// multiple threads concurrently.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        let handle: SequenceExecutionHandleImpl<SequenceResultType> = SequenceExecutionHandleImpl()
        execute(initialTask, with: handle, execution)
        return handle
    }

    // MARK: - Private

    private let taskQueue: DispatchQueue

    private func execute<SequenceResultType>(_ task: Task, with sequenceHandle: SequenceExecutionHandleImpl<SequenceResultType>, _ execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) {
        taskQueue.async {
            guard !sequenceHandle.isCancelled else {
                return
            }

            let result = task.typeErasedExecute()
            let nextExecution = execution(task, result)
            switch nextExecution {
            case .continueSequence(let nextTask):
                self.execute(nextTask, with: sequenceHandle, execution)
            case .endOfSequence(let result):
                sequenceHandle.sequenceDidComplete(with: result)
            }
        }
    }
}

/// Executor of sequences of tasks using the main queue.
/// This exists only to assist with debugging
///
/// - seeAlso: `SequencedTask`.
class SequenceExecutorSerialImpl: SequenceExecutor {

    /// Execute a sequence of tasks from the given initial task.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        let handle: SequenceExecutionHandleImpl<SequenceResultType> = SequenceExecutionHandleImpl()
        execute(initialTask, with: handle, execution)
        return handle
    }

    // MARK: - Private

    private func execute<SequenceResultType>(_ task: Task, with sequenceHandle: SequenceExecutionHandleImpl<SequenceResultType>, _ execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) {
        guard !sequenceHandle.isCancelled else {
            return
        }

        let result = task.typeErasedExecute()
        let nextExecution = execution(task, result)
        switch nextExecution {
        case .continueSequence(let nextTask):
            self.execute(nextTask, with: sequenceHandle, execution)
        case .endOfSequence(let result):
            sequenceHandle.sequenceDidComplete(with: result)
        }
    }
}

private class SequenceExecutionHandleImpl<SequenceResultType>: SequenceExecutionHandle<SequenceResultType> {

    private let latch = CountDownLatch(count: 1)
    private let didCancel = AtomicBool(initialValue: false)

    // Use a lock to ensure result is properly accessed, since the read `await` method
    // may be invoked on a different thread than the write `sequenceDidComplete` method.
    private let resultLock = NSRecursiveLock()
    private var result: SequenceResultType?

    fileprivate var isCancelled: Bool {
        return didCancel.value
    }

    fileprivate override func await(withTimeout timeout: TimeInterval?) throws -> SequenceResultType {
        let didComplete = latch.await(timeout: timeout)
        if !didComplete {
            throw SequenceExecutionError.awaitTimeout
        }

        resultLock.lock()
        defer {
            resultLock.unlock()
        }
        // If latch was counted down, the result must have been set. Therefore, this forced
        // unwrap is safe.
        return result!
    }

    fileprivate func sequenceDidComplete(with result: SequenceResultType) {
        resultLock.lock()
        self.result = result
        resultLock.unlock()

        latch.countDown()
    }

    fileprivate override func cancel() {
        didCancel.compareAndSet(expect: false, newValue: true)
    }
}
