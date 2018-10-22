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

import Concurrency
import XCTest
@testable import NeedleFramework

class PluginizedDependencyGraphParserTests: AbstractPluginizedParserTests {

    func test_parse_withTaskCompleteion_verifyTaskSequence() {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]

        let executor = MockSequenceExecutor()
        var filterCount = 0
        var producerCount = 0
        var parserCount = 0
        executor.executionHandler = { (task: Task, result: Any) in
            if task is PluginizedFileFilterTask {
                filterCount += 1
            } else if task is ASTProducerTask {
                producerCount += 1
            } else if task is PluginizedASTParserTask {
                parserCount += 1
            } else {
                XCTFail()
            }
        }

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            _ = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["ha", "yay", "blah"], using: executor)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
        XCTAssertEqual(filterCount, files.count)
        XCTAssertEqual(producerCount, 10)
        XCTAssertEqual(parserCount, 10)
        XCTAssertEqual(producerCount, parserCount)
    }

    func test_parse_withTaskCompleteion_verifyResults() {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]
        let executor = MockSequenceExecutor()

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            let (components, pluginizedComponents, imports) = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["ha", "yay", "blah"], using: executor)
            let childComponent = components.filter { $0.name == "MyChildComponent" }.first!
            let parentComponent = components.filter { $0.name == "MyComponent" }.first!
            XCTAssertTrue(childComponent.parents.first! == parentComponent)
            XCTAssertEqual(components.count, 11)
            XCTAssertEqual(pluginizedComponents.count, 3)
            XCTAssertEqual(imports, ["import Foundation", "import NeedleFoundation", "import NeedleFoundationExtension", "import RIBs", "import RxSwift", "import ScoreSheet", "import UIKit", "import Utility"])
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
    }
}
