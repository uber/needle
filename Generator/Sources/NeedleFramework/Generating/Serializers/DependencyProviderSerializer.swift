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

/// A serializer that produces the source code for the dependency
/// provider. It's mostly empty as the core logic lives in the
/// class.
class DependencyProviderFuncSerializer: Serializer {

    init(provider: ProcessedDependencyProvider, funcNameSerializer: Serializer, classNameSerializer: Serializer, paramsSerializer: Serializer) {
        self.provider = provider
        self.funcNameSerializer = funcNameSerializer
        self.classNameSerializer = classNameSerializer
        self.paramsSerializer = paramsSerializer
    }

    /// Serialize the data model and produce the entire dependency provider
    /// source code.
    ///
    /// - returns: The entire source code for the dependency provider.
    func serialize() -> String {
        return """
/// \(provider.unprocessed.pathString)
private func \(funcNameSerializer.serialize())(_ component: NeedleFoundation.Scope) -> AnyObject {
    return \(classNameSerializer.serialize())(\(paramsSerializer.serialize()))
}\n
"""
    }

    // MARK: - Private

    private let provider: ProcessedDependencyProvider
    private let funcNameSerializer: Serializer
    private let classNameSerializer: Serializer
    private let paramsSerializer: Serializer
}
