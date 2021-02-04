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
import SourceParsingFramework
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
            if task is PluginizedDeclarationsFilterTask {
                filterCount += 1
            } else if task is ASTProducerTask {
                producerCount += 1
            } else if task is PluginizedDeclarationsParserTask {
                parserCount += 1
            }
        }

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            _ = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["InvalidInits1", "InvalidInits2", "InvalidInits3", "InvalidInits4"], using: executor, withTimeout: 10)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(filterCount, files.count)
        XCTAssertEqual(producerCount, 19)
        XCTAssertEqual(parserCount, 17)
    }

    func test_parse_withTaskCompleteion_verifyResults() {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let executor = MockSequenceExecutor()

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            let (components, pluginizedComponents, imports, _) = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["InvalidInits1", "InvalidInits2", "InvalidInits3", "InvalidInits4"], using: executor, withTimeout: 10)
            let childComponent = components.filter { $0.name == "MyChildComponent" }.first!
            let parentComponent = components.filter { $0.name == "MyComponent" }.first!
            XCTAssertTrue(childComponent.parents.first! == parentComponent)
            XCTAssertEqual(components.count, 16)
            XCTAssertEqual(pluginizedComponents.count, 3)
            XCTAssertEqual(imports, ["import Foundation", "import NeedleFoundation", "import RIBs", "import RxSwift", "import ScoreSheet", "import UIKit", "import Utility", "import protocol Audio.Recordable"])
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_parse_withInvalidComponentInits_verifyError() {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let executor = MockSequenceExecutor()

        do {
            _ = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: [], using: executor, withTimeout: 10)
            XCTFail()
        } catch {
            switch error {
            case GenericError.withMessage(let message):
                XCTAssertTrue(message.contains("is instantiated incorrectly"))
                XCTAssertTrue(message.contains("All components must be instantiated by parent components, by passing `self` as the argument to the parent parameter."))
            default:
                XCTFail()
            }
        }
    }
}
