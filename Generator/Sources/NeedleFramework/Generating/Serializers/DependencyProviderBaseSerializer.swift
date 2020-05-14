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

/// A serializer that produces the source code for the entire dependency
/// provider.
final class DependencyProviderBaseSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter provider: The provider to generate code for.
    /// - parameter classNameSerializer: The serializer that produces
    /// class name.
    /// - parameter propertiesSerializer: The serializer that produces
    /// dependency properties.
    /// - parameter sourceComponentsSerializer: The serializer that produces
    /// source component properties.
    /// - parameter initBodySerializer: The serializer that produces
    /// the body of the initializer.
    init(provider: ProcessedDependencyProvider, classNameSerializer: Serializer, propertiesSerializer: Serializer, sourceComponentsSerializer: Serializer, initBodySerializer: Serializer) {
        self.provider = provider
        self.classNameSerializer = classNameSerializer
        self.propertiesSerializer = propertiesSerializer
        self.sourceComponentsSerializer = sourceComponentsSerializer
        self.initBodySerializer = initBodySerializer
    }

    /// Serialize the data model and produce the entire dependency provider
    /// source code.
    ///
    /// - returns: The entire source code for the dependency provider.
    func serialize() -> String {
        guard !provider.isEmptyDependency else {
            return ""
        }

        return """
        private class \(classNameSerializer.serialize()): \(provider.unprocessed.dependency.name) {
        \(propertiesSerializer.serialize())
        \(sourceComponentsSerializer.serialize())
        \(initBodySerializer.serialize())
        }\n
        """
    }

    // MARK: - Private

    private let provider: ProcessedDependencyProvider
    private let classNameSerializer: Serializer
    private let propertiesSerializer: Serializer
    private let sourceComponentsSerializer: Serializer
    private let initBodySerializer: Serializer
}
