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

class DependencyGraphParserTests: AbstractParserTests {

    func test_parse_withTaskCompleteion_verifyTaskSequence() {
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]

        let executor = MockSequenceExecutor()
        var filterCount = 0
        var producerCount = 0
        var parserCount = 0
        executor.executionHandler = { (task: Task, result: Any) in
            if task is DeclarationsFilterTask {
                filterCount += 1
            } else if task is ASTProducerTask {
                producerCount += 1
            } else if task is DeclarationsParserTask {
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
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureDirUrl()
        let executor = MockSequenceExecutor()

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            let (components, imports) = try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["InvalidInits1", "InvalidInits2", "InvalidInits3", "InvalidInits4"], using: executor, withTimeout: 10)
            let childComponent = components.filter { $0.name == "MyChildComponent" }.first!
            let parentComponent = components.filter { $0.name == "MyComponent" }.first!
            XCTAssertTrue(childComponent.parents.first! == parentComponent)
            XCTAssertEqual(components.count, 12)
            XCTAssertEqual(imports, ["import Foundation", "import RIBs", "import RxSwift", "import UIKit", "import Utility", "import protocol Audio.Recordable"])
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_parse_withInvalidComponentInits_verifyError() {
        let parser = DependencyGraphParser()
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

class MockSequenceExecutor: SequenceExecutor {

    var executeCallCount = 0
    var executionHandler: ((Task, Any) -> ())?

    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        executeCallCount += 1

        var result = try! initialTask.typeErasedExecute()
        var executionResult = execution(initialTask, result)
        executionHandler?(initialTask, result)
        while true {
            switch executionResult {
            case .continueSequence(let task):
                result = try! task.typeErasedExecute()
                executionResult = execution(task, result)
                executionHandler?(task, result)
            case .endOfSequence(let finalResult):
                return MockExecutionHandle(result: finalResult)
            }
        }
    }
}

class MockExecutionHandle<T>: SequenceExecutionHandle<T> {

    var awaitCallCount = 0
    var awaitHandler: ((TimeInterval?) -> ())?

    var cancelCallCount = 0
    var cancelHandler: (() -> ())?

    let result: T

    init(result: T) {
        self.result = result
    }

    override func await(withTimeout timeout: TimeInterval?) throws -> T {
        awaitCallCount += 1
        awaitHandler?(timeout)
        return result
    }

    override func cancel() {
        cancelCallCount += 1
        cancelHandler?()
    }
}
