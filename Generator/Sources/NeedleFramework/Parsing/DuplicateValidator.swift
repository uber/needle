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

/// The duplicate check result.
enum DuplicateValidationResult {
    /// There are no duplicates found.
    case noDuplicates
    /// There is at least a duplicate with the specified name.
    case duplicate(String)
}

/// A utility class that checks if there are any components or dependency
/// protocols with the same names.
class DuplicateValidator {

    /// Validate the given list of components.
    ///
    /// - parameter components: The list of components to validate.
    /// - returns: The validation result.
    func validate(_ components: [ASTComponent]) -> DuplicateValidationResult {
        var map = [String: String]()
        for component in components {
            if map[component.name] == nil {
                map[component.name] = component.name
            } else {
                return .duplicate(component.name)
            }
        }
        return .noDuplicates
    }

    /// Validate the given list of dependencies.
    ///
    /// - parameter dependencies: The list of dependencies to validate.
    /// - returns: The validation result.
    func validate(_ dependencies: [Dependency]) -> DuplicateValidationResult {
        var map = [String: String]()
        for dependency in dependencies {
            if map[dependency.name] == nil {
                map[dependency.name] = dependency.name
            } else {
                return .duplicate(dependency.name)
            }
        }
        return .noDuplicates
    }
}
