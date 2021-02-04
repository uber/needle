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

import XCTest
@testable import NeedleFramework
@testable import SourceParsingFramework
import SwiftSyntax

class DeclarationsParserTaskTests: AbstractParserTests {

    func test_execute_withPrivateProperties_verifyLog() {
        let sourceUrl = fixtureUrl(for: "PrivateSample.swift")
        let sourceContent = try! String(contentsOf: sourceUrl)
        let ast = AST(sourceHash: MD5(string: sourceContent),
                      sourceFileSyntax: try! SyntaxParser.parse(sourceUrl))

        let task = DeclarationsParserTask(ast: ast)
        _ = try! task.execute()

        let expected = ["PrivateDependency (candy: Candy) property is private/fileprivate, therefore inaccessible on DI graph.",
                        "PrivateDependency (cheese: Cheese) property is private/fileprivate, therefore inaccessible on DI graph.",
                        "PrivateComponent (stream: Stream) property is private/fileprivate, therefore inaccessible on DI graph.",
                        "PrivateComponent (donut: Donut) property is private/fileprivate, therefore inaccessible on DI graph."]
        XCTAssertEqual(UnitTestLogger.instance.messages, expected)
    }

    func test_execute_withValidAndInvalidComponentsDependencies_verifyDependencyGraphNode() {
        let sourceUrl = fixtureUrl(for: "ComponentSample.swift")
        let sourceContent = try! String(contentsOf: sourceUrl)
        let imports = ["import UIKit", "import RIBs", "import Foundation", "import protocol Audio.Recordable"]
        let ast = AST(sourceHash: MD5(string: sourceContent),
                      sourceFileSyntax: try! SyntaxParser.parse(sourceUrl))
        
        let task = DeclarationsParserTask(ast: ast)
        let node = try! task.execute()

        XCTAssertEqual(node.components.count, 3)
        
        // Imports
        XCTAssertEqual(node.imports, imports)

        // MyComponent.
        let myComponent = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "MyComponent"
        }!
        XCTAssertEqual(myComponent.expressionCallTypeNames, ["Basket", "Donut", "MyChildComponent", "Stream", "shared"])
        XCTAssertEqual(myComponent.name, "MyComponent")
        XCTAssertEqual(myComponent.dependencyProtocolName, "MyDependency")
        XCTAssertFalse(myComponent.isRoot)
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

        // My2Component.
        let my2Component = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "My2Component"
        }!
        XCTAssertEqual(my2Component.expressionCallTypeNames, ["Apple", "Banana", "Book", "MyStorage", "Wallet", "shared"])
        XCTAssertEqual(my2Component.name, "My2Component")
        XCTAssertEqual(my2Component.dependencyProtocolName, "My2Dependency")
        XCTAssertFalse(my2Component.isRoot)
        XCTAssertEqual(my2Component.properties.count, 3)
        let containsBook = my2Component.properties.contains { (property: Property) -> Bool in
            return property.name == "book" && property.type == "Book"
        }
        XCTAssertTrue(containsBook)

        let containsOptionalWallet = my2Component.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeWallet" && property.type == "Wallet?"
        }
        XCTAssertTrue(containsOptionalWallet)

        // MyDependency.
        XCTAssertEqual(node.dependencies.count, 4)
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

        // My2Dependency.
        let my2Dependency = node.dependencies.first { (dependency: Dependency) -> Bool in
            dependency.name == "My2Dependency"
        }!
        XCTAssertEqual(my2Dependency.name, "My2Dependency")
        XCTAssertEqual(my2Dependency.properties.count, 2)
        let containsBackPack = my2Dependency.properties.contains { (property: Property) -> Bool in
            return property.name == "backPack" && property.type == "Pack"
        }
        XCTAssertTrue(containsBackPack)

        let containsOptionalMoney = my2Dependency.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeMoney" && property.type == "Dollar?"
        }
        XCTAssertTrue(containsOptionalMoney)

        // MyRComp.
        let myRComp = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "MyRComp"
        }!
        XCTAssertEqual(myRComp.expressionCallTypeNames, ["Obj", "shared"])
        XCTAssertEqual(myRComp.name, "MyRComp")
        XCTAssertEqual(myRComp.dependencyProtocolName, "EmptyDependency")
        XCTAssertTrue(myRComp.isRoot)
        XCTAssertEqual(myRComp.properties.count, 1)
        XCTAssertEqual(myRComp.properties, [Property(name: "rootObj", type: "Obj")])

        // Imports.
        XCTAssertEqual(node.imports, ["import UIKit", "import RIBs", "import Foundation", "import protocol Audio.Recordable"])
    }
}
