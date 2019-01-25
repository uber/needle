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

/// The regex pattern that matches any class instantiation expressions
/// with the first capture group capturing the name of the class.
let componentInstantiationRegex = Regex("\\s+([A-Z]\\w+)\\s*\\(\\s*parent\\s*:\\s*")

/// A filter that performs checks based on source file content.
class ContentFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    init(content: String) {
        self.content = content
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the
    func filter() -> Bool {
        // Use simple string matching first since it's more performant.
        if !content.contains("Component") && !content.contains("Dependency") {
            return false
        }

        // Match actual component inheritance using Regex.
        let containsComponentInheritance = (Regex(": *(\(needleModuleName).)?Component *<").firstMatch(in: content) != nil)
        if containsComponentInheritance {
            return true
        }
        let containsDependencyInheritance = (Regex(": *(\(needleModuleName).)?Dependency").firstMatch(in: content) != nil)
        if containsDependencyInheritance {
            return true
        }
        let containsComponentInstantiation = (componentInstantiationRegex.firstMatch(in: content) != nil)
        if containsComponentInstantiation {
            return true
        }

        return false
    }

    // MARK: - Private

    private let content: String
}
