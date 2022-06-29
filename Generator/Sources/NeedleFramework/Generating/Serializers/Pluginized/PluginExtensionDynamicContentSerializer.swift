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

/// A serializer that produces the class definitation source code for the
/// plugin extension provider.
class PluginExtensionDynamicContentSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter component: The pluginized component for which is associated
    ///   with this plugin extension
    init(component: PluginizedComponent) {
        self.component = component
    }

    /// Serialize the data model and produce the source code.
    ///
    /// - returns: The plugin extension class implemention source code.
    func serialize() -> String {
        let properties = serialize(properties: component.pluginExtension.properties)
        
        return """
        /// \(component.data.name) plugin extension
        extension \(component.data.name): ExtensionRegistration {
            public func registerExtensionItems() {
        \(properties)
            }
        }

        """
    }
    
    func serialize(properties: [Property]) -> String {
        return properties.map { property in
            return "        extensionToName[\\\(component.pluginExtension.name).\(property.name)] = \"\(property.name)-\(property.type)\""
        }.joined(separator: "\n")
    }

    // MARK: - Private

    private let component: PluginizedComponent
}
