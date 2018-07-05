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
class PropertiesSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter properties: The properties to generate dependency
    /// provider property getter code for.
    init(processedProperties: [ProcessedProperty]) {
        self.processedProperties = processedProperties
    }

    /// Serialize the property models and produce the source code.
    ///
    /// - returns: The dependency properties source code.
    func serialize() -> String {
        return processedProperties
            .map { (property: ProcessedProperty) in
                serialize(property)
            }
            .joined(separator: "\n")
    }

    // MARK: - Private

    private let processedProperties: [ProcessedProperty]

    private func serialize(_ property: ProcessedProperty) -> String {
        return """
            var \(property.unprocessed.name): \(property.unprocessed.type) {
                return \(property.sourceComponentType.lowercasedFirstChar()).\(property.unprocessed.name)
            }
        """
    }
}
