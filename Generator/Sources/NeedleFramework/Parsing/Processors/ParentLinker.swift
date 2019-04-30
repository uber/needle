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

/// A post processing utility class that links components to their parents.
class ParentLinker: Processor {

    /// Initializer.
    ///
    /// - parameter components: The components to link.
    init(components: [ASTComponent]) {
        self.components = components
    }

    /// Process the data models.
    func process() throws {
        let nameToComponent = components.spm_createDictionary { (component: ASTComponent) -> (String, ASTComponent) in
            (component.name, component)
        }
        for component in components {
            for typeName in component.expressionCallTypeNames {
                if let childComponent = nameToComponent[typeName] {
                    childComponent.parents.append(component)
                }
            }
        }
    }

    // MARK: - Private

    private let components: [ASTComponent]
}
