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

/// A task that loads the content of a file path and returns it as a
/// `String`.
class FileContentLoaderTask: AbstractTask<String> {

    /// Initializer.
    ///
    /// - parameter filePath: The path to the file to be loaded.
    init(filePath: String) {
        self.filePath = filePath
    }

    /// Execute the task and returns the file content.
    ///
    /// - returns: The file content as `String`.
    override func execute() -> String {
        guard let url = URL(string: filePath) else {
            warning("Cannot create file URL from path \(filePath).")
            return ""
        }
        let content = try? String(contentsOf: url)
        if let content = content {
            return content
        } else {
            warning("File content cannot be loaded from \(filePath).")
            return ""
        }
    }

    // MARK: - Private

    private let filePath: String
}
