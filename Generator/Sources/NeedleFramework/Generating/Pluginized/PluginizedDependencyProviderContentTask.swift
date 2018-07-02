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

/// The task that walks through the chain of parents as well as auxillary
/// providers for each dependency item of the dependency protocol that this
/// provider class needs to satisfy.
class PluginizedDependencyProviderContentTask: AbstractTask<[PluginizedProcessedDependencyProvider]> {

    /// Initializer.
    ///
    /// - parameter providers: The list of providers that we need to fill in.
    /// - parameter pluginizedComponents: The list of pluginized components
    ///             to check for auzillary properties.
    init(providers: [DependencyProvider], pluginizedComponents: [PluginizedComponent]) {
        self.providers = providers

        var nonCoreComponentMap = [String: AuxillaryProperties]()
        var pluginExtensionMap = [String: AuxillaryProperties]()
        for pluginizedComponent in pluginizedComponents {
            nonCoreComponentMap[pluginizedComponent.data.name] = AuxillaryProperties(sourceName: pluginizedComponent.nonCoreComponent.name, properties: pluginizedComponent.nonCoreComponent.properties)
            pluginExtensionMap[pluginizedComponent.data.name] = AuxillaryProperties(sourceName: pluginizedComponent.pluginExtension.name, properties:pluginizedComponent.pluginExtension.properties)
        }
        self.nonCoreComponentMap = nonCoreComponentMap
        self.pluginExtensionMap = pluginExtensionMap

        nonCoreComponentNames = Set(pluginizedComponents.map { pluginizedComponent in
            pluginizedComponent.nonCoreComponent.name
        })
    }

    /// Execute the task and returns the processed in-memory dependency graph
    /// data models.
    ///
    /// - returns: The list of `ProcessedDependencyProvider`.
    override func execute() -> [PluginizedProcessedDependencyProvider] {
        return providers.map { (provider: DependencyProvider) -> PluginizedProcessedDependencyProvider in
            do {
                if provider.pathContains(anyOf: nonCoreComponentNames) {
                    return try process(provider, withAuxillaryPropertiesFrom: nonCoreComponentMap, auxillarySourceType: .nonCoreComponent)
                } else {
                    return try process(provider, withAuxillaryPropertiesFrom: pluginExtensionMap, auxillarySourceType: .pluginExtension)
                }
            } catch DependencyProviderContentError.propertyNotFound(let info) {
                var message = "Could not find a provider for \(info.name): \(info.type) which was required by \(info.dependency)."
                if let possibleMatchComponent = info.possibleMatchComponent {
                    message += " Found possible matches \(info.possibleNames) at \(possibleMatchComponent)."
                }
                fatalError(message)
            } catch {
                fatalError("Unhandled error while processing dependency provider content: \(error)")
            }
        }
    }

    // MARK: - Private

    private struct AuxillaryProperties {
        let sourceName: String
        let properties: [Property]
    }

    private let providers: [DependencyProvider]
    // Note: the key is the (class) name of the pluginized component
    private let nonCoreComponentMap: [String: AuxillaryProperties]
    // Note: the key is the (class) name of the pluginized component
    private let pluginExtensionMap: [String: AuxillaryProperties]
    private let nonCoreComponentNames: Set<String>

    private func process(_ provider: DependencyProvider, withAuxillaryPropertiesFrom auxillaryPropertyMap: [String: AuxillaryProperties], auxillarySourceType: AuxillarySourceType) throws -> PluginizedProcessedDependencyProvider  {
        var levelMap = [String: Int]()

        let properties = try provider.dependency.properties.map { (property : Property) -> PluginizedProcessedProperty in
            var level = 0
            let revesedPath = provider.path.reversed()
            for component in revesedPath {
                if component.properties.contains(property) {
                    levelMap[component.name] = level
                    return PluginizedProcessedProperty(data: ProcessedProperty(unprocessed: property, sourceComponentType: component.name), auxillarySourceType: nil, auxillarySourceName: nil)
                } else if let auxillaryProperties = auxillaryPropertyMap[component.name] {
                    if auxillaryProperties.properties.contains(property) {
                        levelMap[component.name] = level
                        return PluginizedProcessedProperty(data: ProcessedProperty(unprocessed: property, sourceComponentType: component.name), auxillarySourceType: auxillarySourceType, auxillarySourceName: auxillaryProperties.sourceName)
                    }
                }
                level += 1
            }
            var possibleMatches = [String]()
            var possibleMatchComponent: String?
            // Second pass, this time only match types to produce helpful warnings
            for component in revesedPath {
                possibleMatches = component.properties.compactMap { componentProperty in
                    if componentProperty.type ==  property.type {
                        return componentProperty.name
                    } else {
                        return nil
                    }
                }
                if !possibleMatches.isEmpty {
                    possibleMatchComponent = component.name
                    break
                }
                if let auxillaryProperties = auxillaryPropertyMap[component.name] {
                    possibleMatches = auxillaryProperties.properties.compactMap { componentProperty in
                        if componentProperty.type ==  property.type {
                            return componentProperty.name
                        } else {
                            return nil
                        }
                    }
                    if !possibleMatches.isEmpty {
                        possibleMatchComponent = auxillaryProperties.sourceName
                        break
                    }
                }
            }
            let info = PropertyNotFoundErrorInfo(dependency: provider.dependency.name, name: property.name, type: property.type, possibleNames: possibleMatches, possibleMatchComponent: possibleMatchComponent)
            throw DependencyProviderContentError.propertyNotFound(info)
        }

        return PluginizedProcessedDependencyProvider(unprocessed: provider, levelMap: levelMap, processedProperties: properties)
    }
}

private extension DependencyProvider {
    func pathContains(anyOf names: Set<String>) -> Bool {
        for component in path {
            if names.contains(component.name) {
                return true
            }
        }
        return false
    }
}
