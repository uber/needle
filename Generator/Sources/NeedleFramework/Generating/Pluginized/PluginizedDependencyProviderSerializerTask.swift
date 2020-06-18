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

/// The task that serializes a list of pluginized processed dependency
/// providers into exportable foramt.
class PluginizedDependencyProviderSerializerTask: AbstractTask<[SerializedProvider]> {

    /// Initializer.
    ///
    /// - parameter providers: The pluginized processed dependency provider
    /// to serialize.
    init(providers: [PluginizedProcessedDependencyProvider]) {
        self.providers = providers
        super.init(id: TaskIds.pluginizedDependencyProviderSerializerTask.rawValue)
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
        var counts = [[PluginizedProcessedProperty]: [PluginizedProcessedDependencyProvider]]()
        for provider in providers {
            let properties = provider.processedProperties
            counts[properties, default: []].append(provider)
        }
        for (baseCount, (_, matchingProviders)) in counts.enumerated() {
            result.append(contentsOf: serialize(matchingProviders, baseCounter: baseCount))
        }
        return result
    }

    // MARK: - Private

    private let providers: [PluginizedProcessedDependencyProvider]

    private func serialize(_ providers: [PluginizedProcessedDependencyProvider], baseCounter: Int) -> [SerializedProvider] {
        var result = [SerializedProvider]()
        let (baseClass, content) = serializedBase(for: providers.first!, counter: baseCounter)
        if providers.first?.data.isEmptyDependency == false {
            result.append(SerializedProvider(content: content, registration: ""))
        }
        for (_, provider) in providers.enumerated() {
            let content = provider.data.isEmptyDependency ? "" : serializedContent(for: provider, baseClassSerializer: baseClass)
            let registration = DependencyProviderRegistrationSerializer(provider: provider.data).serialize()
            result.append(SerializedProvider(content: content, registration: registration))
        }
        return result
    }

    private func serializedContent(for provider: PluginizedProcessedDependencyProvider, baseClassSerializer: Serializer) -> String {
        let classNameSerializer = DependencyProviderClassNameSerializer(provider: provider.data)
        let initBodySerializer = DependencyProviderInitBodySerializer(provider: provider.data)

        let serializer = DependencyProviderSerializer(provider: provider.data, classNameSerializer: classNameSerializer, baseClassSerializer: baseClassSerializer, initBodySerializer: initBodySerializer)
        return serializer.serialize()
    }

    private func serializedBase(for provider: PluginizedProcessedDependencyProvider, counter: Int) -> (Serializer, String) {
        let classNameSerializer = DependencyProviderBaseClassNameSerializer(provider: provider.data)
        let propertiesSerializer = PluginizedPropertiesSerializer(provider: provider)
        let sourceComponentsSerializer = SourceComponentsSerializer(componentTypes: provider.data.levelMap.keys.sorted())
        let initBodySerializer = DependencyProviderBaseInitSerializer(provider: provider.data)

        let serializer = DependencyProviderBaseSerializer(provider: provider.data, classNameSerializer: classNameSerializer, propertiesSerializer: propertiesSerializer, sourceComponentsSerializer: sourceComponentsSerializer, initBodySerializer: initBodySerializer)
        return (classNameSerializer, serializer.serialize())
    }
}
