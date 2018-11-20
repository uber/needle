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

/// A set of utility functions for running processes.
public protocol ProcessUtilities {
    
    /// The current list of processes without controlling ttys in jobs
    /// format.
    var currentNonControllingTTYSProcesses: String { get }
    
    /// A convinient method for killing all the processes with given name.
    /// This executes `/usr/bin/killall -9` with the given process name.
    ///
    /// - parameter processName: The name of the process to kill.
    /// - returns: `true` if succeeded. `false` otherwise.
    func killAll(_ processName: String) -> Bool
}

/// A set of utility functions for running processes.
public class ProcessUtilitiesImpl: ProcessUtilities {
    
    /// Initializer.
    public init() {}
    
    /// The current list of processes without controlling ttys in jobs
    /// format.
    public var currentNonControllingTTYSProcesses: String {
        // Select processes without controlling ttys in jobs format.
        return execute(processName: "ps", withArguments: ["-xj"]).output.lowercased()
    }

    /// A convinient method for killing all the processes with given name.
    /// This executes `/usr/bin/killall -9` with the given process name.
    ///
    /// - parameter processName: The name of the process to kill.
    /// - returns: `true` if succeeded. `false` otherwise.
    public func killAll(_ processName: String) -> Bool {
        let result = execute(path: "/usr/bin/", processName: "killall", withArguments: ["-9", processName])
        return result.error.isEmpty
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
    func execute(path: String = "/bin", processName: String, withArguments arguments: [String] = []) -> (output: String, error: String) {
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
    
    private func read(pipe: Pipe) -> String? {
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
