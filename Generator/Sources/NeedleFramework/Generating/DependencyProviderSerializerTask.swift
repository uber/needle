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
        var counts = [[ProcessedProperty]: [ProcessedDependencyProvider]]()
        for provider in providers {
            let properties = provider.processedProperties
            counts[properties, default: []].append(provider)
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
        let (baseClass, content) = serializedBase(for: providers.first!)
        if providers.first?.isEmptyDependency == false {
            result.append(SerializedProvider(content: content, registration: ""))
        }
        for provider in providers {
            let content = provider.isEmptyDependency ? "" : serializedContent(for: provider, baseClassSerializer: baseClass)
            let registration = DependencyProviderRegistrationSerializer(provider: provider).serialize()
            result.append(SerializedProvider(content: content, registration: registration))
        }
        return result
    }

    private func serializedContent(for provider: ProcessedDependencyProvider, baseClassSerializer: Serializer) -> String {
        let classNameSerializer = DependencyProviderClassNameSerializer(provider: provider)
        let initBodySerializer = DependencyProviderInitBodySerializer(provider: provider)

        let serializer = DependencyProviderSerializer(provider: provider, classNameSerializer: classNameSerializer, baseClassSerializer: baseClassSerializer, initBodySerializer: initBodySerializer)
        return serializer.serialize()
    }

    private func serializedBase(for provider: ProcessedDependencyProvider) -> (Serializer, String) {
        let classNameSerializer = DependencyProviderBaseClassNameSerializer(provider: provider)
        let propertiesSerializer = PropertiesSerializer(processedProperties: provider.processedProperties)
        let sourceComponentsSerializer = SourceComponentsSerializer(componentTypes: provider.levelMap.keys.sorted())
        let initBodySerializer = DependencyProviderBaseInitSerializer(provider: provider)

        let serializer = DependencyProviderBaseSerializer(provider: provider, classNameSerializer: classNameSerializer, propertiesSerializer: propertiesSerializer, sourceComponentsSerializer: sourceComponentsSerializer, initBodySerializer: initBodySerializer)
        return (classNameSerializer, serializer.serialize())
    }
}
