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
        nonCoreComponentNames = Set(pluginizedComponents.map { pluginizedComponent in
            pluginizedComponent.nonCoreComponent.name
        })

        var nonCoreComponentMap = [String: AuxillaryProperties]()
        var pluginExtensionMap = [String: AuxillaryProperties]()
        var auxilarySourceParentDependency = [String: String]()
        for pluginizedComponent in pluginizedComponents {
            nonCoreComponentMap[pluginizedComponent.data.name] = AuxillaryProperties(sourceName: pluginizedComponent.nonCoreComponent.name, properties: pluginizedComponent.nonCoreComponent.properties)
            auxilarySourceParentDependency[pluginizedComponent.nonCoreComponent.name] = pluginizedComponent.nonCoreComponent.dependency.name
            pluginExtensionMap[pluginizedComponent.data.name] = AuxillaryProperties(sourceName: pluginizedComponent.pluginExtension.name, properties:pluginizedComponent.pluginExtension.properties)
            auxilarySourceParentDependency[pluginizedComponent.pluginExtension.name] = pluginizedComponent.data.dependency.name
        }
        self.nonCoreComponentMap = nonCoreComponentMap
        self.pluginExtensionMap = pluginExtensionMap
        self.auxilarySourceParentDependency = auxilarySourceParentDependency

        super.init(id: TaskIds.pluginizedDependencyProviderContentTask.rawValue)
    }

    /// Execute the task and returns the processed in-memory dependency graph
    /// data models.
    ///
    /// - returns: The list of `ProcessedDependencyProvider`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> [PluginizedProcessedDependencyProvider] {
        let result = providers.compactMap { (provider: DependencyProvider) -> PluginizedProcessedDependencyProvider? in
            if provider.pathContains(anyOf: nonCoreComponentNames) {
                return process(provider, withAuxillaryPropertiesFrom: nonCoreComponentMap, auxillarySourceType: .nonCoreComponent)
            } else {
                return process(provider, withAuxillaryPropertiesFrom: pluginExtensionMap, auxillarySourceType: .pluginExtension)
            }
        }
        if result.count < providers.count {
            throw DependencyProviderContentError.missingDependency("Missing one or more dependencies at scope.")
        }
        return result
    }

    // MARK: - Private

    private struct AuxillaryProperties {
        let sourceName: String
        let properties: [Property]
    }

    private let providers: [DependencyProvider]
    private let nonCoreComponentNames: Set<String>
    // The key is the (class) name of the pluginized component.
    private let nonCoreComponentMap: [String: AuxillaryProperties]
    // The key is the (class) name of the pluginized component.
    private let pluginExtensionMap: [String: AuxillaryProperties]
    // The dependency protocol name of the parent of the auxilary property's source.
    // For a property from a plugin extension, the parent is the pluginized component.
    // For a property from a non-core component, the parent is the corresponding core
    // component.
    // For instance, [FooNonCoreComponent: FooDependency] for a non-core component
    // auxilary property. Or [FooPluginExtension: FooDependency] for a plugin
    // extension auxilary property.
    private let auxilarySourceParentDependency: [String: String]

    private func process(_ provider: DependencyProvider, withAuxillaryPropertiesFrom auxillaryPropertyMap: [String: AuxillaryProperties], auxillarySourceType: AuxillarySourceType) -> PluginizedProcessedDependencyProvider?  {
        var levelMap = [String: Int]()

        let properties = provider.dependency.properties.compactMap { (property : Property) -> PluginizedProcessedProperty? in
            // Drop first element, since we should not search in the current scope.
            let searchPath = provider.path.reversed().dropFirst()
            // Level start at 1, since we dropped the current scope.
            var level = 1
            for component in searchPath {
                if component.properties.contains(property) {
                    levelMap[component.name] = level
                    return PluginizedProcessedProperty(data: ProcessedProperty(unprocessed: property, sourceComponentType: component.name), auxillarySourceType: nil, auxillarySourceName: nil)
                } else if let auxillaryProperties = auxillaryPropertyMap[component.name] {
                    // Do not search at the current auxilary scope.
                    let isAtCurrentAuxilaryScope = auxilarySourceParentDependency[auxillaryProperties.sourceName] == provider.dependency.name
                    if !isAtCurrentAuxilaryScope && auxillaryProperties.properties.contains(property) {
                        levelMap[component.name] = level
                        return PluginizedProcessedProperty(data: ProcessedProperty(unprocessed: property, sourceComponentType: component.name), auxillarySourceType: auxillarySourceType, auxillarySourceName: auxillaryProperties.sourceName)
                    }
                }
                level += 1
            }
            var possibleMatches = [String]()
            var possibleMatchComponent: String?
            // Second pass, this time only match types to produce helpful warnings
            for component in searchPath {
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

            // Throw error with informative message.
            var message = "Could not find a provider for (\(property.name): \(property.type)) which was required by \(provider.dependency.name), along the DI branch of \(provider.pathString)."
            if let possibleMatchComponent = possibleMatchComponent {
                message += " Found possible matches \(possibleMatches) at \(possibleMatchComponent)."
            }
            warning(message)
            return nil
        }
        if properties.count < provider.dependency.properties.count {
            return nil
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
