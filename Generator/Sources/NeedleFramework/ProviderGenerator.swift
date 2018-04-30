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

public class ProviderGenerator {
    private var total = 0
    private var allComponents = [Component]()
    private var allDependencies = [Dependency]()

    private func scanFile(atURL url: URL) {
        let fileScanner = FileScanner(url: url)
        if fileScanner.shouldScan() {
            print("Parse:", url.path)
            if let contents = fileScanner.contents {
                let parser = FileParser(contents: contents, path: url.path)
                if let (c, d) = parser.parse() {
                    allComponents += c
                    allDependencies += d
                    total += 1
                }
            }
        }
    }

    public func scanFiles(atPath folderPath: String, withoutSuffixes suffixes: [String]?) {
        let scanner = DirectoryScanner(path: folderPath, withoutSuffixes: suffixes)
        scanner.scan { url in
            scanFile(atURL: url)
        }

        print("files scanned:", total)

        let result = allComponents.map { component in
            component.fakeGenerateForTiming()
        }.joined()

        let outPath = "/tmp/Providers.swift"
        try? result.write(toFile: outPath, atomically: true, encoding: .utf8)
    }

    public init() {}
}

