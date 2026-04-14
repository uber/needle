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

/// A deterministic hasher using FNV-1a (64-bit). Unlike Swift's `Hasher`,
/// this produces the same output across processes and platforms, so hashes
/// can be pre-computed at build time by the Needle code generator.
struct StableFNVHasher {
    private static let offsetBasis: UInt64 = 0xcbf29ce484222325
    private static let prime: UInt64 = 0x100000001b3

    private var hash: UInt64 = offsetBasis

    /// Hash a single string.
    static func hash(_ string: String) -> Int {
        var hasher = StableFNVHasher()
        hasher.combine(string)
        return hasher.finalize()
    }

    /// Hash an array of strings as if they were joined by `separator`.
    /// Produces the same result as `hash(segments.joined(separator: separator))`
    /// without allocating the joined string.
    static func hash(_ segments: [String], separator: String) -> Int {
        var hasher = StableFNVHasher()
        var first = true
        for segment in segments {
            if !first {
                hasher.combine(separator)
            }
            first = false
            hasher.combine(segment)
        }
        return hasher.finalize()
    }

    private mutating func combine(_ string: String) {
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= Self.prime
        }
    }

    private func finalize() -> Int {
        Int(bitPattern: UInt(hash))
    }
}
