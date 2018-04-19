
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

import Commander
import Foundation
import QuartzCore
import SourceKittenFramework

func ScanFiles(atPath folderPath: String, withSuffix suffix: String) {
    let enumerator = FileManager.default.enumerator(atPath: folderPath)

    while let fileName = enumerator?.nextObject() as? String {
        guard fileName.hasSuffix(".swift") else { continue }

        if let file = File(path: folderPath + fileName) {
            let start = CACurrentMediaTime()
            let _ = try? Structure(file: file)
            let stop = CACurrentMediaTime()
            print(fileName, 1000.0*(stop-start))
        }
    }
}

Group {
    let scanCommand = command(Argument<String>("path", description: "Directory to scan"),
                              Option<String>("suffix", default: "", description: "Filename suffix (not including extension)")
    ) { (path, suffix) in
        print(path, suffix)
        ScanFiles(atPath: path, withSuffix: suffix)
    }

    $0.addCommand("scan", "Scan's all swift files in the directory specified", scanCommand)
}.run()
