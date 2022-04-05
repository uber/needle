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

import XCTest
@testable import NeedleFramework

class DependencyProviderSerializerTaskTests: AbstractGeneratorTests {

    func test_execute_withSampleProject_verifySerialization() {
        let (components, imports) = sampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let processedProviders = try! DependencyProviderContentTask(providers: providers).execute()
            for provider in processedProviders {
                let serializedProviders = DependencyProviderSerializerTask(providers: [provider]).execute()
                XCTAssert(serializedProviders.count > 0 && serializedProviders.count < 3)
                verify(provider, against: serializedProviders)
            }
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }

    private func verify(_ provider: ProcessedDependencyProvider, against serializedProviders: [SerializedProvider]) {
        switch provider.unprocessed.pathString {
        case "^->RootComponent->LoggedInComponent->GameComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent", factorycf9c02c4def4e3d508816cd03d3cf415b70dfb0e)

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->GameComponent
private func factorycf9c02c4def4e3d508816cd03d3cf415b70dfb0e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GameDependency1ab5926a977f706d3195Provider(loggedInComponent: parent1(component) as! LoggedInComponent, rootComponent: parent2(component) as! RootComponent)
}

""")
        case "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent", factory3f7d60e2119708f293bac0d8c882e1e0d9b5eda1)

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
private func factory3f7d60e2119708f293bac0d8c882e1e0d9b5eda1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependency97f2595a691a56781aaaProvider(loggedInComponent: parent2(component) as! LoggedInComponent)
}

""")
        case "^->RootComponent->LoggedInComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
registerProviderFactory("^->RootComponent->LoggedInComponent->ScoreSheetComponent", factory62cd15b035cb1b1ab3e00b20504d5a9e5588d7b3)

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
private func factory62cd15b035cb1b1ab3e00b20504d5a9e5588d7b3(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependencycbd7fa4bae2ee69a1926Provider(loggedInComponent: parent1(component) as! LoggedInComponent)
}

""")
        case "^->RootComponent->LoggedOutComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
registerProviderFactory("^->RootComponent->LoggedOutComponent", factory1434ff4463106e5c4f1bb3a8f24c1d289f2c0f2e)

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedOutComponent
private func factory1434ff4463106e5c4f1bb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoggedOutDependencyacada53ea78d270efa2fProvider(rootComponent: parent1(component) as! RootComponent)
}

""")
        case "^->RootComponent->LoggedInComponent":
            XCTAssertEqual(serializedProviders[0].registration, """
registerProviderFactory("^->RootComponent->LoggedInComponent", factoryEmptyDependencyProvider)

""")
        case "^->RootComponent":
            XCTAssertEqual(serializedProviders[0].registration, """
registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)

""")
        default:
            XCTFail("Unverified provider with path \(provider.unprocessed.pathString)")
        }
    }
}
