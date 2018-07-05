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

/// A serializer that produces the dependency properties code for the
/// processed properties.
class PluginizedPropertiesSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter properties: The provider to generate dependency
    /// provider code for.
    init(provider: PluginizedProcessedDependencyProvider) {
        self.provider = provider
    }

    /// Serialize the property models and produce the source code.
    ///
    /// - returns: The dependency properties source code.
    func serialize() -> String {
        return provider.processedProperties
            .map { (property: PluginizedProcessedProperty) in
                serialize(property)
            }
            .joined(separator: "\n")
    }

    // MARK: - Private

    private let provider: PluginizedProcessedDependencyProvider

    private func serialize(_ property: PluginizedProcessedProperty) -> String {
        let auxillaryPrefix = (property.auxillarySourceType == .nonCoreComponent) ? "(" : ""
        let auxillarySuffix = (property.auxillarySourceType == .nonCoreComponent) ? ")" : ""

        let auxillaryAccessor: String = {
            if let type = property.auxillarySourceType {
                switch type {
                case .pluginExtension:
                    return ".pluginExtension"
                case .nonCoreComponent:
                    return ".nonCoreComponent as! \(property.auxillarySourceName!)"
                }
            } else {
                return ""
            }
        }()

        return """
            var \(property.data.unprocessed.name): \(property.data.unprocessed.type) {
                return \(auxillaryPrefix)\(property.data.sourceComponentType.lowercasedFirstChar())\(auxillaryAccessor)\(auxillarySuffix).\(property.data.unprocessed.name)
            }
        """
    }
}
