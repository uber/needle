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

/// A set of paths used within the Needle project.
class Paths {
    
    /// The Needle reposiroty's root directory path.
    static let repoRoot: String = {
        let result = ProcessUtilities.execute(processName: "git", withArguments: ["rev-parse", "--show-toplevel"])
        if result.output.isEmpty {
            fatalError("Cannot locate git process.")
        }
        let path = result.output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return path.hasSuffix("/") ? path : path + "/"
    }()
    
    /// The generator directory path.
    static let generator: String = {
        return repoRoot + "Generator/"
    }()
    
    /// The generator binary's path.
    static let generatorBin: String = {
        return generator + "bin/"
    }()
    
    /// The generator archieve's path.
    static let generatorArchieve: String = {
        return generator + "./.build/release/needle"
    }()
    
    /// The generator binary's path.
    static let generatorBinary: String = {
        return generatorBin + "needle"
    }()
}
