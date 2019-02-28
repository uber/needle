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

/// A post processing utility class that links components to their dependency
/// protocols.
class DependencyLinker: Processor {

    /// Initializer.
    ///
    /// - parameter components: The components to link.
    /// - parameter dependencies: The dependency protocols to link.
    init(components: [ASTComponent], dependencies: [Dependency]) {
        self.components = components
        self.dependencies = dependencies
    }

    /// Process the data models.
    func process() throws {
        var nameToDependency: [String: Dependency] = [emptyDependency.name: emptyDependency]
        for dependency in dependencies {
            nameToDependency[dependency.name] = dependency
        }
        for component in components {
            if let dependency = nameToDependency[component.dependencyProtocolName] {
                component.dependencyProtocol = dependency
            } else if !Dependency.isEmptyDependency(name: component.dependencyProtocolName) {
                throw GenericError.withMessage("Missing dependency protocol data model with name \(component.dependencyProtocolName), for \(component.name).")
            }
        }
    }

    // MARK: - Private

    private let components: [ASTComponent]
    private let dependencies: [Dependency]
}
