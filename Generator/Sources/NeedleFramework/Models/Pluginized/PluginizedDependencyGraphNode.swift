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

/// An extended data model representing a node in the dependency graph.
/// The components may be pluginized components or regular ones.
struct PluginizedDependencyGraphNode {
    /// The list of pluginized components in this node.
    let pluginizedComponents: [PluginizedASTComponent]
    /// The list of non-core components in this node.
    let nonCoreComponents: [ASTComponent]
    /// The list of plugin extensions in this node.
    let pluginExtensions: [PluginExtension]
    /// The list of regular components in this node.
    let components: [ASTComponent]
    /// The list of dependencies in this node.
    let dependencies: [Dependency]
    /// The list of import statements including the `import` keyword.
    let imports: [String]
}
