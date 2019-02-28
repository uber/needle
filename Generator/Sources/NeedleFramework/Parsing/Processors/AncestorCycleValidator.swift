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

/// A post processing utility class that checks if there are any cycles
/// in the dependency graph's ancestor paths.
class AncestorCycleValidator: Processor {

    /// Initializer.
    ///
    /// - parameter components: The list of components to validate.
    init(components: [ASTComponent]) {
        self.components = components
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if any cycles are detected.
    func process() throws {
        for component in components {
            if let cyclePath = findAncestorCycle(component, visitedComponents: []) {
                let pathNames = cyclePath.map { (element: ASTComponent) -> String in
                    element.name
                } + [component.name]
                throw GenericError.withMessage("Dependency cycle detected along the path of \(pathNames.joined(separator: "->"))")
            }
        }
    }

    // MARK - Private

    private let components: [ASTComponent]

    private func findAncestorCycle(_ component: ASTComponent, visitedComponents: [ASTComponent]) -> [ASTComponent]? {
        // Use DFS to detect cycles faster. Given the limited number of
        // elements, using a more complex algorithm like Tarjan's seems
        // unnecessary.
        let alreadyVisited = visitedComponents.contains { (element: ASTComponent) -> Bool in
            element.name == component.name
        }
        if alreadyVisited {
            return visitedComponents
        } else {
            for ancestor in component.parents {
                if let cyclePath = findAncestorCycle(ancestor, visitedComponents: visitedComponents + [component]) {
                    return cyclePath
                }
            }
            return nil
        }
    }
}
