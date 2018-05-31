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

class AbstractGeneratorTests: XCTestCase {
    
    /// Retrieve the parsed component data models for the sample project.
    ///
    /// - returns: The list of component data models.
    func sampleProjectComponents() -> [Component] {
        let parser = DependencyGraphParser()
        let fixturesURL = sampleProjectUrl()

        let executeTaskHandler = { (task: SequencedTask<DependencyGraphNode>) -> SequenceExecutionHandle<DependencyGraphNode> in
            var task = task
            while true {
                let executionResult = task.execute()
                switch executionResult {
                case .continueSequence(let nextTask):
                    task = nextTask
                case .endOfSequence(let result):
                    let executionHandle = MockExecutionHandle(defaultResult: DependencyGraphNode(components: [], dependencies: [], imports: []))
                    executionHandle.result = result
                    return executionHandle
                }
            }
        }
        let executor = MockSequenceExecutor(executeTaskHandler: executeTaskHandler)

        do {
            return try parser.parse(from: fixturesURL, excludingFilesWithSuffixes: ["ha", "yay", "blah"], using: executor)
        } catch {
            fatalError("\(error)")
        }
    }

    /// Retrieve the URL for the sample project folder.
    ///
    /// - returns: The sample project folder URL.
    func sampleProjectUrl() -> URL {
        var dir = URL(fileURLWithPath: #file)
        for _ in 0 ..< 5 {
            dir = dir.deletingLastPathComponent()
        }
        dir.appendPathComponent("Sample/TicTacToe/Sources/")
        return dir
    }
}
