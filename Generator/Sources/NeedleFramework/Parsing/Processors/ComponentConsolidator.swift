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

/// A post processing utility class that consolidates component extensions
/// with the corresponding components.
class ComponentConsolidator: Processor {

    /// Initializer.
    ///
    /// - parameter components: The components to consolidate into.
    /// - parameter componentExtensions: The component extensions to
    /// consolidate with.
    init(components: [ASTComponent], componentExtensions: [ASTComponentExtension]) {
        self.components = components
        self.componentExtensions = componentExtensions
    }

    /// Process the data models.
    func process() throws {
        let nameToComponent = components.spm_createDictionary { (component: ASTComponent) -> (String, ASTComponent) in
            (component.name, component)
        }
        for componentExtension in componentExtensions {
            let component = nameToComponent[componentExtension.name]
            if let component = component {
                component.properties.append(contentsOf: componentExtension.properties)
                component.expressionCallTypeNames.append(contentsOf: componentExtension.expressionCallTypeNames)
            } else {
                throw GenericError.withMessage("\(componentExtension.name) only has extension but missing declaration.")
            }
        }
    }

    // MARK: - Private

    private let components: [ASTComponent]
    private let componentExtensions: [ASTComponentExtension]
}
