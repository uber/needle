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

/// The execution result of a single `SequencedTask`.
enum ExecutionResult<SequenceResultType> {
    /// The execution of the sequence should continue with another task.
    case continueSequence(SequencedTask<SequenceResultType>)
    /// The end of the entire task sequence with produced result.
    case endOfSequence(SequenceResultType)
}

/// A task that after execution can optionally return another task to form a sequence
/// of tasks to be executed, or an end result produced by the entire sequence.
// This cannot be a protocol, since `ExecutionResult` references this as a type.
// Protocols with associatedType cannot be directly used as types.
class SequencedTask<SequenceResultType> {

    /// Execute this task.
    ///
    /// - returns: The execution result of this task.
    func execute() -> ExecutionResult<SequenceResultType> {
        fatalError("execute not yet implemented.")
    }
}
