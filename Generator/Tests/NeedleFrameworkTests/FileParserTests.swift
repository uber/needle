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

class FileParserTests: XCTestCase {
    let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures/")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testParseFile_verifyResults() {
        let url = fixturesURL.appendingPathComponent("sample.swift")
        if let contents = try? String(contentsOfFile: url.path, encoding: .utf8) {
            let parser = FileParser(contents: contents, path: "/tmp/random/sample.swift")
            if let (comps, deps) = parser.parse() {
                print(comps, deps)
                XCTAssert(comps.count == 2)
                XCTAssert(comps[0].members.count == 3)
                XCTAssert(comps[1].members.count == 2)
                XCTAssert(deps.count == 2)
                XCTAssert(deps[0].members.count == 3)
                XCTAssert(deps[1].members.count == 2)
            } else {
                XCTFail("Expected a non-nil response from the parser")
            }
        } else {
            XCTFail("Trouble reading fixture file: " + url.path)
        }
    }
}
