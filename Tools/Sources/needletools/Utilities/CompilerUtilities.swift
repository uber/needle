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

/// Swift compiler utilities.
class CompilerUtilities {

    /// Compile and archive the DI code generator.
    ///
    /// - returns: `true` is archiving succeeded. `false` otherwise.
    /// If failed, the result contains the error message.
    static func archiveGenerator() -> (status: Bool, error: String) {
        let arguments = [
            "build",
            "--package-path", Paths.generator,
            "-c", "release",
            "-Xswiftc",
            "-static-stdlib"
        ]
        let result = ProcessUtilities.execute(processName: "swift", withArguments: arguments)
        return (result.error.isEmpty, result.error)
    }
}
