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

/// The task that serialized a list of processed dependency providers into
/// exportable `String`.
class DependencyProviderSerializerTask: SequencedTask<[SerializedDependencyProvider]> {

    /// The processed dependency provider to serialize.
    let providers: [ProcessedDependencyProvider]

    /// Initializer.
    ///
    /// - parameter providers: The processed dependency provider to serialize.
    init(providers: [ProcessedDependencyProvider]) {
        self.providers = providers
    }

    /// Execute the task and returns the in-memory serialized dependency
    /// provider data models.
    ///
    /// - returns: `.endOfSequence` with a list of `SerializedDependencyProvider`.
    override func execute() -> ExecutionResult<[SerializedDependencyProvider]> {
        let serialized = providers.map { (provider: ProcessedDependencyProvider) in
            return serialize(provider)
        }
        return .endOfSequence(serialized)
    }

    // MARK: - Private

    private func serialize(_ provider: ProcessedDependencyProvider) -> SerializedDependencyProvider {
        let content = serializedContent(for: provider)
        let registration = serializedRegistration(for: provider)
        return SerializedDependencyProvider(content: content, registration: registration)
    }

    // MARK: - Content

    private func serializedContent(for provider: ProcessedDependencyProvider) -> String {
        guard !provider.isEmptyDependency else {
            return ""
        }

        let propertyVars = serialize(provider.processedProperties)
        let sourceComponentVars = serialize(provider.levelMap)
        let initContent = serializeInitContent(with: provider.levelMap)
        let className = serializedClassName(for: provider)

        return """
        /// \(provider.unprocessed.pathString)
        private class \(className): \(provider.unprocessed.dependency.name) {
        \(propertyVars)
        \(sourceComponentVars)
            init(component: ComponentType) {
        \(initContent)
            }
        }\n
        """
    }

    private func serializedClassName(for provider: ProcessedDependencyProvider) -> String {
        let pathId = String(provider.unprocessed.pathString.hashValue).replacingOccurrences(of: "-", with: "_")
        return "\(provider.unprocessed.dependency.name)\(pathId)Provider"
    }

    private func serialize(_ properties: [ProcessedProperty]) -> String {
        return properties
            .map { (property: ProcessedProperty) in
                serialize(property)
            }
            .joined(separator: "\n")
    }

    private func serialize(_ property: ProcessedProperty) -> String {
        return """
            var \(property.unprocessed.name): \(property.unprocessed.type) {
                return \(property.sourceComponentType.lowercasedFirstChar()).\(property.unprocessed.name)
            }
        """
    }

    private func serialize(_ levelMap: [String: Int]) -> String {
        return levelMap.keys.map { (componentType: String) in
            return "    private let \(componentType.lowercasedFirstChar()): \(componentType)"
        }
        .joined(separator: "\n")
    }

    private func serializeInitContent(with levelMap: [String: Int]) -> String {
        return levelMap.map { (componentType: String, level: Int) in
            return "        \(componentType.lowercasedFirstChar()) = component\(String(repeating: ".parent", count: level)) as! \(componentType)"
        }
        .joined(separator: "\n")
    }

    // MARK: - Registration

    private func serializedRegistration(for provider: ProcessedDependencyProvider) -> String {
        let providerName = provider.isEmptyDependency ? "EmptyDependencyProvider" : serializedClassName(for: provider)
        return """
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "\(provider.unprocessed.pathString)") { component in
            return \(providerName)(component: component)
        }\n
        """
    }
}
