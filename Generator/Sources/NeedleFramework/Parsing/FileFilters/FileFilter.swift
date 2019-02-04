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

/// The base protocol of a file filter. It determines if the parsing
/// sequence should continue based on the file.
protocol FileFilter: AnyObject {

    /// Execute the filter.
    ///
    /// - returns: `true` if the filter passed and the task should either
    /// execute the next filter or move onto the next task in the sequence
    /// if there are no more filters. `false` if the filter failed, and
    /// the task sequence should abort.
    func filter() -> Bool
}
