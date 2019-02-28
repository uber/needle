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
import SourceParsingFramework

/// A task that loads the content of a file path and returns it as a
/// `String`.
class FileContentLoaderTask: AbstractTask<String> {

    /// Initializer.
    ///
    /// - parameter filePath: The path to the file to be loaded.
    init(filePath: String) {
        self.filePath = filePath
        super.init(id: TaskIds.fileContentLoaderTask.rawValue)
    }

    /// Execute the task and returns the file content.
    ///
    /// - returns: The file content as `String`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> String {
        let url = URL(fileURLWithPath: filePath)
        return try CachedFileReader.instance.content(forUrl: url)
    }

    // MARK: - Private

    private let filePath: String
}
