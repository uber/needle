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

/// Utilities for performing unix process operations.
class ProcessUtilities {
    
    /// Move the given source file to the given destination.
    ///
    /// - parameter source: The path to the source to move.
    /// - parameter destination: The destionation path to move to.
    /// - returns: `true` if succeeded. `false` otherwise. If failed,
    /// the error message is included in the result.
    static func move(_ source: String, to destination: String) -> (status: Bool, error: String) {
        let result = execute(path: "/bin/", processName: "mv", withArguments: [source, destination])
        return (result.error.isEmpty, result.error)
    }

    /// Execute the given process with given arguments and return the
    /// standard output as a `String`.
    ///
    /// - parameter path: The path to the process to execute.
    /// - parameter process: The name of the process to execute.
    /// - parameter arguments: The list of arguments to supply to the
    /// process.
    /// - returns: The standard output content as a single `String` and
    /// the standard error content as a single `String`.
    static func execute(path: String = "/usr/bin/", processName: String, withArguments arguments: [String] = []) -> (output: String, error: String) {
        let justName = processName.starts(with: "/") ? String(processName.suffix(from: processName.index(processName.startIndex, offsetBy: 1))) : processName
        let justPath = path.hasSuffix("/") ? path : path + "/"

        let task = Process()
        task.launchPath = justPath + justName
        task.arguments = arguments
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        let errorPipe = Pipe()
        task.standardError = errorPipe
        task.launch()

        let output = read(pipe: outputPipe) ?? ""
        let error = read(pipe: errorPipe) ?? ""
        return (output, error)
    }

    // MARK: - Private

    static private func read(pipe: Pipe) -> String? {
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
