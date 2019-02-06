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

/// A filter that performs checks if the file content contains any
/// plugin extension protocol declarations.
class PluginExtensionProtocolFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    init(content: String) {
        self.content = content
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the file content contains plugin extension
    /// protocol declarations.
    func filter() -> Bool {
        // Use simple string matching first since it's more performant.
        if !content.contains("PluginExtension") {
            return false
        }

        // Match actual syntax using Regex.
        let containsPluginExtensionInheritance = (Regex.foundationInheritanceRegex(forProtocol: "PluginExtension").firstMatch(in: content) != nil)
        if containsPluginExtensionInheritance {
            return true
        }

        return false
    }

    // MARK: - Private

    private let content: String
}
