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

class DependencyGraphPrinter {
    private let components: [Component]
    
    init(components: [Component]) {
        self.components = components
    }
    
    func printDIStructure(withRootComponentName rootComponentName: String) {
        var childrenDictionary = [String: [Component]]()
        
        let parentChildTuples: [(Component, Component)] = components.flatMap { component in
            return component.parents.map { ($0, component) }
        }
        parentChildTuples.forEach { (parent, child) in
            var children = childrenDictionary[parent.name] ?? [Component]()
            children.append(child)
            childrenDictionary[parent.name] = children
        }
        
        var sortedChildren = [String: [Component]]()
        childrenDictionary.forEach { (parentName, children) in
            sortedChildren[parentName] = children.sorted { $0.name < $1.name}
        }
        
        printChildren(ofParent: rootComponentName,
                      withChildrenDictionary: sortedChildren,
                      atLevel: 0)
    }
    
    private func printChildren(ofParent componentName: String,
                               withChildrenDictionary childrenDictionary: [String: [Component]],
                               atLevel level: Int,
                               usingLevelSeparator levelSeparator: String = "\t",
                               usingComponentSuffix componentSuffix: String = componentClassName) {
        let separator = String(repeating: levelSeparator, count: level)
        
        let name: String = {
            guard componentName.hasSuffix(componentSuffix) else { return componentName }
            return String(componentName.dropLast(componentSuffix.count))
        }()
        
        let result = separator + name
        print(result)
        
        let children = childrenDictionary[componentName]
        children?.forEach { child in
            printChildren(ofParent: child.name,
                          withChildrenDictionary: childrenDictionary,
                          atLevel: level + 1)
        }
    }
}
