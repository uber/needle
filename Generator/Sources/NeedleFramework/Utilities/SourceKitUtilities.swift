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

/// A set of utility functions for the SourceKitService.
public protocol SourceKitUtilities {
    /// Check if the sourcekit daemon process is running by searching through
    /// all processes without ttys.
    var isSourceKitRunning: Bool { get }

    /// Issue the initialize command to the SourceKit service.
    func initialize()

    /// Kill the SourceKitService process.
    ///
    /// - note: This method does not use the `shutdown` supported by the
    /// actual SourceKit service. Instead it kills the entire process.
    /// - returns: `true` if killing the process succeeded. `false otherwise.
    func killProcess() -> Bool
}

/// A set of utility functions for the SourceKitService.
public class SourceKitUtilitiesImpl: SourceKitUtilities {
    
    /// Initializer.
    ///
    /// - parameter processUtilities: The process utilities to use.
    public init(processUtilities: ProcessUtilities) {
        self.processUtilities = processUtilities
    }

    /// Check if the sourcekit daemon process is running by searching through
    /// all processes without ttys.
    public var isSourceKitRunning: Bool {
        let result = processUtilities.currentNonControllingTTYSProcesses
        // These process names are found in library_wrapper_sourcekitd.swift
        // of SourceKittenFramework.
        return result.contains("libsourcekitdInProc") || result.contains("sourcekitd.framework")
    }

    /// Issue the initialize command to the SourceKit service.
    public func initialize() {
        sourcekitd_initialize()
    }
    
    /// Kill the SourceKitService process.
    ///
    /// - note: This method does not use the `shutdown` supported by the
    /// actual SourceKit service. Instead it kills the entire process.
    /// - returns: `true` if killing the process succeeded. `false otherwise.
    public func killProcess() -> Bool {
        return processUtilities.killAll("SourceKitService")
    }
    
    // MARK: - Private
    
    private let processUtilities: ProcessUtilities
}
