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

import SourceKittenFramework
import XCTest
@testable import SourceParsingFramework

class ASTUtilsTests: AbstractSourceParsingTests {

    func test_inheritedTypes_withSingleLine_verifyResult() {
        let structure = ast(for: "SingleLineInheritedTypes.swift").substructures[0]
        let types = structure.inheritedTypes

        XCTAssertEqual(types, ["SuperClass<Blah,Foo,Bar>"])
    }

    func test_inheritedTypes_withMultiLine_verifyResult() {
        let structure = ast(for: "MultiLineInheritedTypes.swift").substructures[0]
        let types = structure.inheritedTypes

        XCTAssertEqual(types, ["SuperClass<Blah,Foo,Bar>"])
    }

    private func ast(for fileName: String) -> Structure {
        let fileUrl = fixtureUrl(for: fileName)
        let content = try! String(contentsOf: fileUrl)
        let file = File(contents: content)
        return try! Structure(file: file)
    }
}
