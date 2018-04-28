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

/// A task that after execution can optionally return another task to form a sequence
/// of tasks to be executed.
public protocol SequencedTask: AnyObject {

    /// Execute this task and the returned task if there is one.
    ///
    /// - returns: An optional task to be executed after this task is executed. If a
    /// new task is returned, this task and the returned one effectively forms a task
    /// sequence to be executed like an assembly line. If `nil` is returned, this
    /// task effectively becomes the terminating task, marking the completion of the
    /// entire task sequence.
    func execute() -> SequencedTask?
}
