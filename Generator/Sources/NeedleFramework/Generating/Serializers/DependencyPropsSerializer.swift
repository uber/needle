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

class DependencyPropsSerializer: Serializer {
    
    init(component: Component) {
        self.component = component
    }
    
    func serialize() -> String {
        if component.isLeaf {
            return """
extension \(component.name): Registration {
    public func registerItems() {
\(serialize(component.dependency))
    }
}

"""
        } else {
            return """
extension \(component.name): Registration {
    public func registerItems() {
\(serialize(component.dependency))
\(serialize(component.properties))
    }
}

"""
        }
    }

    // MARK: - Private

    private func serialize(_ dependency: Dependency) -> String {
        let dependencyName = dependency.name
        return dependency.properties.map { property in
            return "        keyPathToName[\\\(dependencyName).\(property.name)] = \"\(property.name)-\(property.type)\""
        }.joined(separator: "\n")
    }

    private func serialize(_ properties: [Property]) -> String {
        return properties.filter { property in
            !property.isInternal
        }.map { property in
            return "        localTable[\"\(property.name)-\(property.type)\"] = { [unowned self] in self.\(property.name) as Any }"
        }.joined(separator: "\n")
    }

    private let component: Component
}

