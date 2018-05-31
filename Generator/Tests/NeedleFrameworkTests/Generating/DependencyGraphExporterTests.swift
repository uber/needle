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

class MockExecutionTaskHandler<T> {

    private let defaultResult: T

    init(defaultResult: T) {
        self.defaultResult = defaultResult
    }

    func execute(task: SequencedTask<T>) -> SequenceExecutionHandle<T> {
        var task = task
        while true {
            let executionResult = task.execute()
            switch executionResult {
            case .continueSequence(let nextTask):
                task = nextTask
            case .endOfSequence(let result):
                let executionHandle = MockExecutionHandle(defaultResult: defaultResult)
                executionHandle.result = result
                return executionHandle
            }
        }
    }

}

class DependencyGraphExporterTests: AbstractGeneratorTests {
    let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/")

    @available(OSX 10.12, *)
    static var allTests = [
        ("test_export_verifyContent", test_export_verifyContent),
    ]

    @available(OSX 10.12, *)
    func test_export_verifyContent() {
        let components = sampleProjectComponents()
        let mockTaskHandler = MockExecutionTaskHandler(defaultResult: [SerializedDependencyProvider]())
        let executor = MockSequenceExecutor(executeTaskHandler: mockTaskHandler.execute)
        let exporter = DependencyGraphExporter()

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("generated.swift")
        try? exporter.export(components: components, to: outputURL.path, using: executor)
        let generated = try? String(contentsOf: outputURL)
        XCTAssertNotNil(generated, "Could not read the generated file")

        let url = fixturesURL.appendingPathComponent("generated.swift")
        let expected = try? String(contentsOf: url)
        XCTAssertNotNil(expected, "Could not read in fixture file")

        XCTAssertEqual(generated, expected)
    }
}
