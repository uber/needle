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

class RegEx {
    let expression: NSRegularExpression

    init(_ expr: String) {
        do {
            expression = try NSRegularExpression(pattern: expr, options: [])
        } catch {
            fatalError("Could not create parser for expression : \(expr)")
        }
    }

    func firstMatch(_ line: String) -> NSTextCheckingResult? {
        return expression.firstMatch(in: line, options: [], range: NSRange(location:0, length:line.count))
    }
}

