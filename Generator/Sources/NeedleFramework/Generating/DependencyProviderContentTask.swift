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

/// Errors that can occur during dependency checking stage.
enum DependencyProviderContentError: Error {
    /// Could not find a dependency along the path to the root.
    case missingDependency(String)
}


/// The task that walks through the chain of parents for each dependency
/// item of the dependency protocol that this provider class needs to satisfy.
class DependencyProviderContentTask: AbstractTask<[ProcessedDependencyProvider]> {

    /// Initializer.
    ///
    /// - parameter providers: The list of providers that we need to fill in
    init(providers: [DependencyProvider]) {
        self.providers = providers
        super.init(id: TaskIds.dependencyProviderContentTask.rawValue)
    }

    /// Execute the task and returns the processed in-memory dependency graph
    /// data models.
    ///
    /// - returns: The list of `ProcessedDependencyProvider`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> [ProcessedDependencyProvider] {
        let result = try providers.compactMap { (provider: DependencyProvider) throws -> ProcessedDependencyProvider? in
            process(provider)
        }
        if result.count < providers.count {
            throw DependencyProviderContentError.missingDependency("Missing one or more dependencies at scope.")
        }
        return result
    }

    // MARK: - Private

    private let providers: [DependencyProvider]

    private func process(_ provider: DependencyProvider) -> ProcessedDependencyProvider?  {
        var levelMap = [String: Int]()

        let properties = provider.dependency.properties.compactMap { (property : Property) -> ProcessedProperty? in
            // Drop first element, since we should not search in the current scope.
            let searchPath = provider.path.reversed().dropFirst()
            // Level start at 1, since we dropped the current scope.
            var level = 1
            for component in searchPath {
                if component.properties.contains(property) {
                    levelMap[component.name] = level
                    return ProcessedProperty(unprocessed: property, sourceComponentType: component.name)
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

        return ProcessedDependencyProvider(unprocessed: provider, levelMap: levelMap, processedProperties: properties)
    }
}
