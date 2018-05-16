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

import SourceKittenFramework
import XCTest
@testable import NeedleFramework

class ASTParserTaskTests: AbstractParserTests {
    
    func test_execute_withValidAndInvalidComponentsDependencies_verifyDependencyGraphNode() {
        let sourceUrl = fixtureUrl(for: "ComponentSample.swift")
        let sourceContent = try! String(contentsOf: sourceUrl)
        let structure = try! Structure(file: File(contents: sourceContent))

        let task = ASTParserTask(structure: structure)
        let result = task.execute()

        switch result {
        case .continueSequence(_):
            XCTFail()
        case .endOfSequence(let node):
            XCTAssertEqual(node.components.count, 2)

            let myComponent = node.components.first { (component: ASTComponent) -> Bool in
                component.name == "MyComponent"
            }!
            XCTAssertEqual(myComponent.expressionCallTypeNames, ["Stream", "Donut", "shared", "MyChildComponent", "Basket"])
            XCTAssertEqual(myComponent.name, "MyComponent")
            XCTAssertEqual(myComponent.dependencyProtocolName, "MyDependency")
            XCTAssertEqual(myComponent.properties.count, 4)
            let containsStream = myComponent.properties.contains { (property: Property) -> Bool in
                return property.name == "stream" && property.type == "Stream"
            }
            XCTAssertTrue(containsStream)
            let containsDonut = myComponent.properties.contains { (property: Property) -> Bool in
                return property.name == "donut" && property.type == "Donut"
            }
            XCTAssertTrue(containsDonut)
            let containsBasket = myComponent.properties.contains { (property: Property) -> Bool in
                return property.name == "sweetsBasket" && property.type == "Basket"
            }
            XCTAssertTrue(containsBasket)
            let containsChildComponent = myComponent.properties.contains { (property: Property) -> Bool in
                return property.name == "myChildComponent" && property.type == "MyChildComponent"
            }
            XCTAssertTrue(containsChildComponent)

            let my2Component = node.components.first { (component: ASTComponent) -> Bool in
                component.name == "My2Component"
            }!
            XCTAssertEqual(my2Component.expressionCallTypeNames, ["shared", "Banana", "Apple", "Book"])
            XCTAssertEqual(my2Component.name, "My2Component")
            XCTAssertEqual(my2Component.dependencyProtocolName, "My2Dependency")
            XCTAssertEqual(my2Component.properties.count, 1)
            let containsBook = my2Component.properties.contains { (property: Property) -> Bool in
                return property.name == "book" && property.type == "Book"
            }
            XCTAssertTrue(containsBook)

            XCTAssertEqual(node.dependencies.count, 2)
            let myDependency = node.dependencies.first { (dependency: Dependency) -> Bool in
                dependency.name == "MyDependency"
            }!
            XCTAssertEqual(myDependency.name, "MyDependency")
            XCTAssertEqual(myDependency.properties.count, 2)
            let containsCandy = myDependency.properties.contains { (property: Property) -> Bool in
                return property.name == "candy" && property.type == "Candy"
            }
            XCTAssertTrue(containsCandy)
            let containsCheese = myDependency.properties.contains { (property: Property) -> Bool in
                return property.name == "cheese" && property.type == "Cheese"
            }
            XCTAssertTrue(containsCheese)

            let my2Dependency = node.dependencies.first { (dependency: Dependency) -> Bool in
                dependency.name == "My2Dependency"
            }!
            XCTAssertEqual(my2Dependency.name, "My2Dependency")
            XCTAssertEqual(my2Dependency.properties.count, 1)
            let containsBackPack = my2Dependency.properties.contains { (property: Property) -> Bool in
                return property.name == "backPack" && property.type == "Pack"
            }
            XCTAssertTrue(containsBackPack)
        }
    }
}
