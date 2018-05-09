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

import RxSwift

extension ObservableType {

    /// Transform this sequence of non-optional values into a sequence of tuples of the previously emitted
    /// value from the source, and the new non-optional value.
    ///
    /// - note: The first emission of the returned sequence always has the previous value as nil. The returned
    ///   sequence does not block for at least two values to emit from the original source, before emitting.
    /// - returns: An observable of previous and current non-optional value tuples.
    func withPreviousValue() -> Observable<(E?, E)> {
        let initial: E? = nil
        let seed: E? = initial

        return scan((seed, initial)) { (seedPrevious: (seed: E?, previous: E?), current: E?) -> (E?, E?) in
            return (seedPrevious.previous, current)
            }
            .flatMap { (previousValue: E?, newValue: E?) -> Observable<(E?, E)> in
                guard let newValue = newValue else {
                    return Observable<(E?, E)>.empty()
                }
                return Observable<(E?, E)>.just((previousValue, newValue))
        }
    }
}
