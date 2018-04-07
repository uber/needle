
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
import QuartzCore
import SourceKittenFramework

guard CommandLine.argc >= 2 else {
    print("Usage :", CommandLine.arguments[0], "<folder_to_scan>")
    exit(1)
}

let folderPath = CommandLine.arguments[1]
let enumerator = FileManager.default.enumerator(atPath: folderPath)

while let fileName = enumerator?.nextObject() as? String {
    guard fileName.hasSuffix(".swift") else { continue }

    if let file = File(path: folderPath + fileName) {
        let start = CACurrentMediaTime()
        let _ = try Structure(file: file)
        let stop = CACurrentMediaTime()
        print(fileName, 1000.0*(stop-start))
    }
}

