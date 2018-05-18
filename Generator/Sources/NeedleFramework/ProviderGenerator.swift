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

import Concurrency
import Foundation

public class ProviderGenerator {
    private let total = AtomicInt(initialValue: 0)
    private var allComponents = [Component]()
    private var allDependencies = [Dependency]()
    private let lock = NSRecursiveLock()

    private func scanFile(atURL url: URL) {
        let fileScanner = FileScanner(url: url)
        if fileScanner.shouldScan() {
            print("Parse:", url.path)
            if let contents = fileScanner.contents {
                let parser = FileParser(contents: contents, path: url.path)
                if let (c, d) = parser.parse() {
                    lock.lock()
                    allComponents += c
                    allDependencies += d
                    lock.unlock()
                    total.incrementAndGet()
                }
            }
        }
    }

    public enum Mode {
        case serial
        case two
        case burst
        case overlap
    }

    public func scanFiles(mode: Mode, atPath folderPath: String, withoutSuffixes suffixes: [String]?) {
        let scanner = DirectoryScanner(path: folderPath, withoutSuffixes: suffixes)

        switch mode {
        case .serial:
            scanner.scan { url in
                scanFile(atURL: url)
            }
        case .two:
            let queue = DispatchQueue(label: "scanner-serial", qos: .userInteractive)
            scanner.scan { url in
                queue.async {
                    self.scanFile(atURL: url)
                }
            }

            // Wait for queue to drain
            queue.sync(flags: .barrier) {}
        case .burst:
            var all = [URL]()
            scanner.scan { url in
                all.append(url)
            }
            let allFiles = all
            DispatchQueue.concurrentPerform(iterations: allFiles.count) { i in
                scanFile(atURL: allFiles[i])
            }
        case .overlap:
            let queue = DispatchQueue(label: "scanner-concurrent", qos: .userInteractive, attributes: .concurrent)
            scanner.scan { url in
                queue.async {
                    self.scanFile(atURL: url)
                }
            }

            // Wait for queue to drain
            queue.sync(flags: .barrier) {}
        }
        print("files scanned:", total.value)

//        let result = allComponents.map { component in
//            component.fakeGenerateForTiming()
//        }.joined()
//
//        let outPath = "/tmp/Providers.swift"
//        try? result.write(toFile: outPath, atomically: true, encoding: .utf8)
    }

    public init() {}
}

