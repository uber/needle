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

class Benchmark {

    static var benchmarks = [String: Benchmark]()
    static let benchmarkInitLock = NSLock()


    private var duration: UInt64 = 0
    private var durationCalculationLock = NSLock()

    static func instance(group: String) -> Benchmark {
        benchmarkInitLock.lock()
        if benchmarks[group] == nil {
            benchmarks[group] = Benchmark()
        }
        benchmarkInitLock.unlock()

        return benchmarks[group]!
    }

    static func printDiagnostics() {
        for (key, benchmark) in benchmarks {
            print("Cumulative time spent in \(key) : \(benchmark.duration) ns")
        }
    }

    func execute<T>(block:@autoclosure () -> T) -> T {
        let startTime = DispatchTime.now().uptimeNanoseconds
        let result: T = block()
        let endTime = DispatchTime.now().uptimeNanoseconds
        durationCalculationLock.lock()
        duration += endTime - startTime
        durationCalculationLock.unlock()
        return result
    }
}
