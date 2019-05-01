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

import Concurrency
import Foundation
import SourceParsingFramework

/// A task that checks the various aspects of a file, including if its
/// content contains any component, Pluginized component, or non-core
/// component implementations, dependency protocol declarations or
/// component instantiations, to determine if the file should to be parsed
/// for AST.
class PluginizedDeclarationsFilterTask: BaseFileFilterTask {

    /// Initializer.
    ///
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If the given URL filename's suffix matches any in the
    /// this list, the URL will be excluded.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If the given URL's path contains any elements in this list, the
    /// URL will be excluded.
    init(url: URL, exclusionSuffixes: [String], exclusionPaths: [String]) {
        super.init(url: url, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths, taskId: TaskIds.pluginizedDeclarationsFilterTask.rawValue)
    }

    /// Create a set of filters for the given file content.
    ///
    /// - parameter content: The file content the returned filters should
    /// be applied on.
    /// - returns: A set of filters to use on the given content.
    override func filters(for content: String) -> [FileFilter] {
        return [
            RootComponentImplFilter(content: content),
            ComponentImplFilter(content: content),
            DependencyProtocolFilter(content: content),
            ComponentInitFilter(content: content),
            PluginizedComponentImplFilter(content: content),
            NonCoreComponentImplFilter(content: content),
            PluginExtensionProtocolFilter(content: content)
        ]
    }
}
