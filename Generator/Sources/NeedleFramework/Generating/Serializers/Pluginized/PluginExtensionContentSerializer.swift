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
class PluginExtensionContentSerializer: Serializer {

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
        let processedProperties = component.pluginExtension.properties.map { property in
            ProcessedProperty(unprocessed: property, sourceComponentType: component.nonCoreComponent.name)
        }
        let properties = PropertiesSerializer(processedProperties: processedProperties).serialize()
        let extensionClassName = PluginExtensionClassNameSerializer(component: component).serialize()
        let pluginziedComponentPropertyName = component.data.name.lowercasedFirstChar()
        let nonCoreComponentPropertyName = component.nonCoreComponent.name.lowercasedFirstChar()

        return """
        /// \(component.data.name) plugin extension
        private class \(extensionClassName): \(component.pluginExtension.name) {
        \(properties)
            private unowned let \(nonCoreComponentPropertyName): \(component.nonCoreComponent.name)
            init(component: NeedleFoundation.Scope) {
                let \(pluginziedComponentPropertyName) = component as! \(component.data.name)
                \(nonCoreComponentPropertyName) = \(pluginziedComponentPropertyName).nonCoreComponent as! \(component.nonCoreComponent.name)
            }
        }\n
        """
    }

    // MARK: - Private

    private let component: PluginizedComponent
}
