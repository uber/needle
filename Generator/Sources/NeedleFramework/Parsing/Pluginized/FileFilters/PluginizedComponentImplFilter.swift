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
/// Pluginized component class implementations.
class PluginizedComponentImplFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    init(content: String) {
        self.content = content
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the file content contains Pluginized component
    /// class implementations.
    func filter() -> Bool {
        // Use simple string matching first since it's more performant.
        if !content.contains("PluginizedComponent") {
            return false
        }

        // Match actual syntax using Regex.
        let containsPluginizedComponentInheritance = (Regex(": *(\(needleModuleName).)?PluginizedComponent *<").firstMatch(in: content) != nil)
        if containsPluginizedComponentInheritance {
            return true
        }

        return false
    }

    // MARK: - Private

    private let content: String
}
