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

class GeneratorTests: XCTestCase {

    func test_generate_noThrow_verifySingleCall() {
        let generator = MockGenerator()

        XCTAssertEqual(generator.generateCallCount, 0)

        try! generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, retryParsingOnTimeoutLimit: 1000)

        XCTAssertEqual(generator.generateCallCount, 1)
    }

    func test_generate_throwTimeoutError_withRetry_verifyRetry() {
        let generator = MockGenerator()
        generator.generateClosure = {
            throw DependencyGraphParserError.timeout("", 123, true)
        }

        XCTAssertEqual(generator.generateCallCount, 0)

        do {
            try generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, retryParsingOnTimeoutLimit: 3)
            XCTFail()
        } catch {
            XCTAssertTrue(error is GeneratorError)
        }

        XCTAssertEqual(generator.generateCallCount, 3)
    }

    func test_generate_throwTimeoutError_withNoRetry_verifySingleCall() {
        let generator = MockGenerator()
        generator.generateClosure = {
            throw DependencyGraphParserError.timeout("", 123, true)
        }

        XCTAssertEqual(generator.generateCallCount, 0)

        do {
            try generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, retryParsingOnTimeoutLimit: 0)
            XCTFail()
        } catch {
            XCTAssertTrue(error is GeneratorError)
        }

        XCTAssertEqual(generator.generateCallCount, 1)
    }
}

private class MockGenerator: Generator {

    fileprivate var generateCallCount = 0
    fileprivate var generateClosure: (() throws -> ())? = nil

    override func generate(from sourceRootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, using executor: SequenceExecutor) throws {
        generateCallCount += 1
        try generateClosure?()
    }
}
