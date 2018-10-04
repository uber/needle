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

class FileEnumeratorTests: AbstractParserTests {

    static var allTests = [
        ("test_enumerate_withSourcesFile_verifyUrls", test_enumerate_withSourcesFile_verifyUrls),
    ]

    func test_enumerate_withSourcesFile_verifyUrls() {
        let sourcesListUrl = fixtureUrl(for: "sources_list.txt")
        let enumerator = FileEnumerator()
        var urls = [String]()
        enumerator.enumerate(from: sourcesListUrl) { (url: URL) in
            urls.append(url.absoluteString)
        }

        let expectedUrls = [
            "file:///Users/yiw/Uber/ios/vendor/box/Box/Box.swift",
            "file:///Users/yiw/Uber/ios/vendor/box/Box/BoxType.swift",
            "file:///Users/yiw/Uber/ios/vendor/box/Box/MutableBox.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/IntExtensions.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSON.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONDecodable.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONEncodable.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONEncodingDetector.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONLiteralConvertible.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONOptional.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONParser.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONParsing.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONSerializing.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONSubscripting.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/ConcurrentReadVariable.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/DispatchOperators.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/DispatchQueue.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/ReadWriteLock.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/RecursiveSyncLock.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/Sychronized.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/SynchronizedDictionary.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Date/Date.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Errors/Asserts.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/DeviceExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/Enumerations.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/FoundationExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/Math.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/ObfuscationExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/SequenceExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/FileSystem/FileManaging.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/LogModelMetadata/LogModelMetadata.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Obfuscation/Obfuscation.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BuildType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BuildVersion.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BundleType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Runtime/RunType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/TestMocks/Manual/ManualProtocolMocks.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/TestMocks/PresidioFoundationProtocolMocks.swift",
        ]

        XCTAssertEqual(urls, expectedUrls)
    }
}
