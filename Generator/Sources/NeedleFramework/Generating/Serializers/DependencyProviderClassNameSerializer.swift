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

/// A serializer that produces the func name for the dependency provider.
class DependencyProviderFuncNameSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter classNameSerializer: The serializer for the class name.
    /// - parameter paramsSerializer: The serializer for the parameters.
    init(classNameSerializer: Serializer, paramsSerializer: Serializer) {
        self.classNameSerializer = classNameSerializer
        self.paramsSerializer = paramsSerializer
    }

    /// Serialize the data model and produce the func name code.
    ///
    /// - returns: The func name code.
    func serialize() -> String {
        let classId = String(classNameSerializer.serialize().shortSHA256Value)
        let paramsId = String(paramsSerializer.serialize().shortSHA256Value)
        return "factory\(classId)\(paramsId)"
    }

    // MARK: - Private

    private let classNameSerializer: Serializer
    private let paramsSerializer: Serializer
}

/// A serializer that produces the class name for the dependency provider base class.
final class DependencyProviderClassNameSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter provider: The provider to generate class name for.
    /// - parameter counter: When making multiple instances, use a unique value here.
    init(provider: ProcessedDependencyProvider) {
        self.provider = provider
    }

    /// Serialize the data model and produce the class name code.
    ///
    /// - returns: The class name code.
    func serialize() -> String {
        let pathId = String(provider.unprocessed.pathString.shortSHA256Value)
        return "\(provider.unprocessed.dependency.name)\(pathId)Provider"
    }

    // MARK: - Private

    private let provider: ProcessedDependencyProvider
}
