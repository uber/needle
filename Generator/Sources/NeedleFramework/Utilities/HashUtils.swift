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
import SourceParsingFramework
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG



/// Calculates the MD5 hash of the input string
func MD5(string: String) -> String {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    let messageData = string.data(using:.utf8)!
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        messageData.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }

    return digestData.map( { String(format: "%02hhx", $0) }).joined()
}

/// Generates a cumulative hash of all the hashEntries
func generateCumulativeHash(hashEntries: Set<HashEntry>) -> String {
    let hashCollection = hashEntries.sorted().reduce(into: "") {
        (resultString, entry) in
        resultString.append(contentsOf: "\(entry.name):\(entry.hash)\n")
    }

    return MD5(string: hashCollection)
}

struct HashEntry: Hashable, Comparable {
    let name: String
    let hash: String

    static func < (lhs: HashEntry, rhs: HashEntry) -> Bool {
        return lhs.name < rhs.name
    }
}
