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

/// Struct that gives us detailed information when we cannot find
/// a dependency after walking up the chain.
struct PropertyNotFoundErrorInfo {
    let dependency: String
    let name: String
    let type: String
    let possibleNames: [String]
    let possibleMatchComponent: String?
}

/// Enum of possible errors we may throw from this task.
enum DependencyProviderContentError: Error {
    case propertyNotFound(PropertyNotFoundErrorInfo)
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
    override func execute() -> [ProcessedDependencyProvider] {
        return providers.map { (provider: DependencyProvider) -> ProcessedDependencyProvider in
            do {
                return try process(provider)
            } catch DependencyProviderContentError.propertyNotFound(let info) {
                var message = "Could not find a provider for (\(info.name): \(info.type)) which was required by \(info.dependency), along the DI branch of \(provider.pathString)."
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

    private let providers: [DependencyProvider]

    private func process(_ provider: DependencyProvider) throws -> ProcessedDependencyProvider  {
        var levelMap = [String: Int]()

        let properties = try provider.dependency.properties.map { (property : Property) -> ProcessedProperty in
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
            let info = PropertyNotFoundErrorInfo(dependency: provider.dependency.name, name: property.name, type: property.type, possibleNames: possibleMatches, possibleMatchComponent: possibleMatchComponent)
            throw DependencyProviderContentError.propertyNotFound(info)
        }

        return ProcessedDependencyProvider(unprocessed: provider, levelMap: levelMap, processedProperties: properties)
    }

}

