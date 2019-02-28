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

class GeneratorTests: XCTestCase {

    func test_generate_noThrow_verifySingleCall() {
        let sourceKitUtilities = MockSourceKitUtilities()
        let generator = MockGenerator(sourceKitUtilities: sourceKitUtilities)

        XCTAssertEqual(generator.generateCallCount, 0)

        try! generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, parsingTimeout: 10, exportingTimeout: 10, retryParsingOnTimeoutLimit: 1000, concurrencyLimit: nil)

        XCTAssertEqual(generator.generateCallCount, 1)
    }

    func test_generate_throwTimeoutError_withRetry_verifyRetry() {
        let sourceKitUtilities = MockSourceKitUtilities()
        sourceKitUtilities.isSourceKitRunningHandler =  {
            return true
        }
        sourceKitUtilities.killProcessHandler =  {
            return true
        }

        let generator = MockGenerator(sourceKitUtilities: sourceKitUtilities)
        generator.generateClosure = {
            throw DependencyGraphParserError.timeout("", 123)
        }

        XCTAssertEqual(generator.generateCallCount, 0)
        XCTAssertEqual(sourceKitUtilities.isSourceKitRunningCallCount, 0)
        XCTAssertEqual(sourceKitUtilities.initializeCallCount, 0)
        XCTAssertEqual(sourceKitUtilities.killProcessCallCount, 0)

        do {
            try generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, parsingTimeout: 10, exportingTimeout: 10, retryParsingOnTimeoutLimit: 3, concurrencyLimit: nil)
            XCTFail()
        } catch {
            XCTAssertTrue(error is GenericError)
        }

        XCTAssertEqual(generator.generateCallCount, 3)
        XCTAssertEqual(sourceKitUtilities.isSourceKitRunningCallCount, 3)
        XCTAssertEqual(sourceKitUtilities.initializeCallCount, 2)
        XCTAssertEqual(sourceKitUtilities.killProcessCallCount, 2)
    }

    func test_generate_throwTimeoutError_withNoRetry_verifySingleCall() {
        let sourceKitUtilities = MockSourceKitUtilities()
        sourceKitUtilities.isSourceKitRunningHandler =  {
            return true
        }
        sourceKitUtilities.killProcessHandler =  {
            return true
        }

        let generator = MockGenerator(sourceKitUtilities: sourceKitUtilities)
        generator.generateClosure = {
            throw DependencyGraphParserError.timeout("", 123)
        }

        XCTAssertEqual(generator.generateCallCount, 0)

        do {
            try generator.generate(from: [], excludingFilesEndingWith: [], excludingFilesWithPaths: [], with: [], nil, to: "blah", shouldCollectParsingInfo: true, parsingTimeout: 10, exportingTimeout: 10, retryParsingOnTimeoutLimit: 0, concurrencyLimit: nil)
            XCTFail()
        } catch {
            XCTAssertTrue(error is GenericError)
        }

        XCTAssertEqual(generator.generateCallCount, 1)
        XCTAssertEqual(sourceKitUtilities.isSourceKitRunningCallCount, 1)
        XCTAssertEqual(sourceKitUtilities.initializeCallCount, 0)
        XCTAssertEqual(sourceKitUtilities.killProcessCallCount, 0)
    }
}

private class MockGenerator: Generator {

    fileprivate var generateCallCount = 0
    fileprivate var generateClosure: (() throws -> ())? = nil

    override func generate(from sourceRootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, using executor: SequenceExecutor, withParsingTimeout parsingTimeout: Double, exportingTimeout: Double) throws {
        generateCallCount += 1
        try generateClosure?()
    }
}

private class MockSourceKitUtilities: SourceKitUtilities {
    
    fileprivate var initializeHandler: (() -> ())?
    fileprivate var initializeCallCount = 0
    
    fileprivate var killProcessHandler: (() -> Bool)?
    fileprivate var killProcessCallCount = 0
    
    fileprivate var isSourceKitRunningHandler: (() -> Bool)?
    fileprivate var isSourceKitRunningCallCount = 0
    
    var isSourceKitRunning: Bool {
        isSourceKitRunningCallCount += 1
        if let isSourceKitRunningHandler = isSourceKitRunningHandler {
            return isSourceKitRunningHandler()
        } else {
            return false
        }
    }
    
    func initialize() {
        initializeCallCount += 1
        if let initializeHandler = initializeHandler {
            initializeHandler()
        }
    }
    
    func killProcess() -> Bool {
        killProcessCallCount += 1
        if let killProcessHandler = killProcessHandler {
            return killProcessHandler()
        } else {
            return false
        }
    }
}
