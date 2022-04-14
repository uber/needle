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
import TSCBasic

/// The task that serializes a list of processed dependency providers into
/// exportable foramt.
class DependencyProviderSerializerTask: AbstractTask<[SerializedProvider]> {

    /// Initializer.
    ///
    /// - parameter providers: The processed dependency provider to serialize.
    init(providers: [ProcessedDependencyProvider]) {
        self.providers = providers
        super.init(id: TaskIds.dependencyProviderSerializerTask.rawValue)
    }

    /// Execute the task and returns the in-memory serialized dependency
    /// provider data models.
    ///
    /// - returns: The list of `SerializedProvider`.
    override func execute() -> [SerializedProvider] {
        var result = [SerializedProvider]()
        // Group the providers based on where the properties are coming from
        // This will allow us to extract common code for multiple depndency providers
        // into common base classes
        var counts = OrderedDictionary<[ProcessedProperty], [ProcessedDependencyProvider]>()
        for provider in providers {
            let properties = provider.processedProperties
            counts[properties] = (counts[properties] ?? []) + [provider]
        }
        for matchingProviders in counts.values {
            result.append(contentsOf: serialize(matchingProviders))
        }
        return result
    }

    // MARK: - Private

    private let providers: [ProcessedDependencyProvider]

    private func serialize(_ providers: [ProcessedDependencyProvider]) -> [SerializedProvider] {
        var result = [SerializedProvider]()
        let (classNameSerializer, content) = serializedClass(for: providers.first!)
        if providers.first?.isEmptyDependency == false {
            result.append(SerializedProvider(content: content, registration: "", attributes: ProviderAttributes()))
        }
        for provider in providers {
            let paramsSerializer = DependencyProviderParamsSerializer(provider: provider)
            let funcNameSerializer = DependencyProviderFuncNameSerializer(classNameSerializer: classNameSerializer, paramsSerializer: paramsSerializer)
            let content = serializedContent(for: provider, classNameSerializer: classNameSerializer, paramsSerializer: paramsSerializer, funcNameSerializer: funcNameSerializer)
            let registration = DependencyProviderRegistrationSerializer(provider: provider, factoryFuncNameSerializer: funcNameSerializer).serialize()
            let attributes = calculateAttributes(for: provider, funcNameSerializer: funcNameSerializer)
            result.append(SerializedProvider(content: content, registration: registration, attributes: attributes))
        }
        return result
    }

    private func serializedContent(for provider: ProcessedDependencyProvider, classNameSerializer: Serializer, paramsSerializer: Serializer, funcNameSerializer: Serializer) -> String {
        if provider.isEmptyDependency {
            return ""
        }
        return DependencyProviderFuncSerializer(provider: provider, funcNameSerializer: funcNameSerializer, classNameSerializer: classNameSerializer, paramsSerializer: paramsSerializer).serialize()
    }

    private func serializedClass(for provider: ProcessedDependencyProvider) -> (Serializer, String) {
        let classNameSerializer = DependencyProviderClassNameSerializer(provider: provider)
        let propertiesSerializer = PropertiesSerializer(processedProperties: provider.processedProperties)
        let sourceComponentsSerializer = SourceComponentsSerializer(componentTypes: provider.levelMap.keys.sorted())
        let initBodySerializer = DependencyProviderBaseInitSerializer(provider: provider)

        let serializer = DependencyProviderClassSerializer(provider: provider, classNameSerializer: classNameSerializer, propertiesSerializer: propertiesSerializer, sourceComponentsSerializer: sourceComponentsSerializer, initBodySerializer: initBodySerializer)
        return (classNameSerializer, serializer.serialize())
    }

    private func calculateAttributes(for provider: ProcessedDependencyProvider, funcNameSerializer: Serializer) -> ProviderAttributes {
        if provider.isEmptyDependency {
            return ProviderAttributes()
        }
        var maxLevel: Int = 0
        for (_, level) in provider.levelMap {
            if level > maxLevel {
                maxLevel = level
            }
        }
        var attributes = ProviderAttributes()
        if maxLevel > 0 {
            attributes.maxLevel = maxLevel
        }
        attributes.factoryName = funcNameSerializer.serialize()
        return attributes
    }
}
