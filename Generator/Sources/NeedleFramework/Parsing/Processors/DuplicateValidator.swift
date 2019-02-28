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
import SourceParsingFramework

/// A post processing utility class that checks if there are any components
/// or dependency protocols with the same names.
class DuplicateValidator: Processor {

    /// Initializer.
    ///
    /// - parameter components: The list of components to validate.
    /// - parameter dependencies: The list of dependencies to validate.
    init(components: [ASTComponent], dependencies: [Dependency]) {
        self.components = components
        self.dependencies = dependencies
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if any components or dependencies have
    /// the same type names.
    func process() throws {
        try validate(components)
        try validate(dependencies)
    }

    // MARK - Private

    private let components: [ASTComponent]
    private let dependencies: [Dependency]

    private func validate(_ components: [ASTComponent]) throws {
        var map = [String: String]()
        for component in components {
            if map[component.name] == nil {
                map[component.name] = component.name
            } else {
                throw GenericError.withMessage("Needle does not support components with the same name \(component.name)")
            }
        }
    }

    private func validate(_ dependencies: [Dependency]) throws {
        var map = [String: String]()
        for dependency in dependencies {
            if map[dependency.name] == nil {
                map[dependency.name] = dependency.name
            } else {
                throw GenericError.withMessage("Needle does not support dependency protocols with the same name \(dependency.name)")
            }
        }
    }
}
