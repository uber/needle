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

class FileScannerTests: XCTestCase {
    let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures/")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_bogusFile_verifyShouldNotScan() {
        let scanner = FileScanner(url: URL(fileURLWithPath: "/random/foo/xyzabc"))
        XCTAssertFalse(scanner.shouldScan())
    }

    func test_noComponentFile_verifyShouldNotScan() {
        let url = fixturesURL.appendingPathComponent("nocomp.swift")
        let scanner = FileScanner(url: url)
        XCTAssertFalse(scanner.shouldScan())
    }

    func test_noComponentFile_verifyShouldScan() {
        let url = fixturesURL.appendingPathComponent("yescomp.swift")
        let scanner = FileScanner(url: url)
        XCTAssertTrue(scanner.shouldScan())
    }
}
