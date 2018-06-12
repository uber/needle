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

/// An individual unit of work that can be executed in a concurrent
/// environment by an executor.
// Task cannot be generic since it needs to be referenced by the executor
// class which cannot provide type information for specific tasks.
protocol Task {

    /// Execute this task without any type information.
    ///
    /// - returns: The execution result of this task.
    // Return type cannot be generic since it needs to be referenced by the
    // executor class which cannot provide type information for results.
    func typeErasedExecute() -> Any
}

/// The base abstraction of a task that has a defined execution result
/// type.
// This class is used to allow subclasses to declare result type generics,
// while allowing the internal executor implementations to operate on the
// non-generic, type-erased `Task` protocol, since Swift does not support
// wildcard generics.
class AbstractTask<ResultType>: Task {

    /// Execute this task without any type information.
    ///
    /// - note: This method is only used for internal executor uses.
    /// - returns: The execution result of this task.
    final func typeErasedExecute() -> Any {
        return execute()
    }

    /// Execute this task and return the result.
    ///
    /// - returns: The execution result of this task.
    func execute() -> ResultType {
        fatalError("\(self).execute is not yet implemented.")
    }
}
