//
//  Copyright (c) 2026. Uber Technologies
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
@testable import NeedleFoundation

class StableFNVHasherTests: XCTestCase {

    // These expected values must match the hashes produced by the Needle code
    // generator (DependencyProvider.pathHash). If this test fails, the runtime
    // and codegen FNV implementations have diverged.

    func test_stablePathHash_matchesCodegenHashes() {
        let cases: [(path: String, expected: Int)] = [
            ("^->RootComponent", -3171806194175578407),
            ("^->RootComponent->LoggedInComponent", -860435685645118366),
            ("^->RootComponent->LoggedOutComponent", 6062161635131552075),
            ("^->RootComponent->LoggedInComponent->GameComponent", -322842588535013842),
            ("^->RootComponent->LoggedInComponent->ScoreSheetComponent", -8216646763020093181),
            ("^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent", 3176341359983622439),
        ]

        for (path, expected) in cases {
            let segments = path.components(separatedBy: "->")
            let hash = StableFNVHasher.hash(segments, separator: "->")
            XCTAssertEqual(hash, expected, "Hash mismatch for path: \(path)")
        }
    }

    func test_stablePathHash_matchesSingleStringHash() {
        // Hashing segments with separator should produce the same result
        // as hashing the joined string directly.
        let paths = [
            ["^", "AppComponent", "RootComponent"],
            ["^", "AppComponent", "RootComponent", "LoggedInComponent", "GameComponent"],
        ]

        for segments in paths {
            let joinedHash = StableFNVHasher.hash(segments.joined(separator: "->"))
            let segmentHash = StableFNVHasher.hash(segments, separator: "->")
            XCTAssertEqual(joinedHash, segmentHash, "Segment hash != joined hash for: \(segments)")
        }
    }
}
