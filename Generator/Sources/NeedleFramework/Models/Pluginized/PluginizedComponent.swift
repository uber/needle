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

/// An extended data model representing the AST of a component that may be
/// a pluginized component with a corresponding non-core component. This
/// representation does not have the reference between the pluginized component
/// and its non-core one. Since it is the pure AST representation, it only
/// has the type name of the non-core component.
class PluginizedASTComponent {
    /// The actual data of this component.
    let data: ASTComponent
    /// The type name of the plugin extension.
    let pluginExtensionType: String
    /// The type name of the non-core component.
    let nonCoreComponentType: String
    /// The linked non-core component.
    var nonCoreComponent: ASTComponent?
    /// The linked plugin extension.
    var pluginExtension: PluginExtension?

    /// Convert the mutable reference type into a thread-safe value type.
    var valueType: PluginizedComponent {
        return PluginizedComponent(data: data.valueType, nonCoreComponent: nonCoreComponent!.valueType, pluginExtension: pluginExtension!)
    }

    /// Initializer.
    ///
    /// - parameter data: The actual data of this component.
    /// - parameter pluginExtensionType: The type name of the plugin extension.
    /// - parameter nonCoreComponentType: The type name of the non-core
    /// component.
    init(data: ASTComponent, pluginExtensionType: String, nonCoreComponentType: String) {
        self.data = data
        self.pluginExtensionType = pluginExtensionType
        self.nonCoreComponentType = nonCoreComponentType
    }
}

/// A data model representing an extended component that may be a pluginized
/// component with a referenced non-core component.
struct PluginizedComponent {
    /// The actual data of this component.
    let data: Component
    /// The non-core component.
    let nonCoreComponent: Component
    /// The plugin extension.
    let pluginExtension: PluginExtension
}
