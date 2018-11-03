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

/// Check if the sourcekit deamon process is running by searching through
/// all processes without ttys.
var isSourceKitRunning: Bool {
    // Select processes without controlling ttys in jobs format.
    let result = ProcessUtilities.execute(process: "/bin/ps", withArguments: ["-xj"])
    return result.lowercased().contains("sourcekit")
}

/// A set of utility functions for running processes.
class ProcessUtilities {

    /// Execute the given process with given arguments and return the
    /// standard output as a `String`.
    ///
    /// - parameter process: The process to run.
    /// - parameter arguments: The list of arguments to supply to the
    /// process.
    /// - returns: The standard output content as a single `String`.
    static func execute(process: String, withArguments arguments: [String] = []) -> String {
        let task = Process()
        task.launchPath = process
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
