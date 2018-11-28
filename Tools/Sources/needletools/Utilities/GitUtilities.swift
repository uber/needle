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

/// The errors produced by executing Git operations.
enum GitErrors: Error {
    /// The generic error with details in the associated value.
    case generic(String)
}

/// Utility functions for invoking the GIT process.
class GitUtilities {

    /// Retrieve the head commit SHA.
    ///
    /// - throws: `GitErrors.generic` if the current working directory
    /// is not a git repository.
    /// - returns: The head commit SHA.
    static func headSHA() throws -> String {
        let result = ProcessUtilities.execute(processName: "git", withArguments: ["rev-parse", "HEAD"])
        if result.output.isEmpty {
            throw GitErrors.generic(result.error)
        } else {
            return result.output
        }
    }

    /// Switch the master branch.
    ///
    /// - throws: `GitErrors.generic` if checkout failed.
    static func checkoutMaster() throws {
        let result = ProcessUtilities.execute(processName: "git", withArguments: ["checkout", "master"])
        if result.error != "Switched to branch \'master\'\n" && result.error != "Already on \'master\'\n" {
            throw GitErrors.generic(result.error)
        }
    }

    /// Create a new tag with given version and push it to remote.
    ///
    /// - throws: If creating the tag failed.
    static func createTag(withVersion version: String) throws {
        let result = ProcessUtilities.execute(processName: "git", withArguments: ["tag", version])
        if result.error.contains("fatal") {
            throw GitErrors.generic(result.error)
        }

        _ = ProcessUtilities.execute(processName: "git", withArguments: ["push", "origin", "--tags"])
    }

    /// Push a single file change to remote master branch.
    ///
    /// - parameter file: The single file to be committed and pushed.
    /// - parameter version: The version number of the release.
    /// - throws: If pushing the file failed.
    static func push(file: String, withVersion version: String) throws {
        var result = ProcessUtilities.execute(processName: "git", withArguments: ["add", file])
        if !result.error.isEmpty {
            throw GitErrors.generic(result.error)
        }

        result = ProcessUtilities.execute(processName: "git", withArguments: ["commit", "-m", "'\(version)'"])
        if !result.error.isEmpty {
            throw GitErrors.generic(result.error)
        }

        result = ProcessUtilities.execute(processName: "git", withArguments: ["push", "origin", "master"])
        if !result.output.isEmpty {
            throw GitErrors.generic(result.error)
        }
    }
}
