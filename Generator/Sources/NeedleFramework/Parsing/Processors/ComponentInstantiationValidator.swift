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

/// A post processing utility class that checks if any components are
/// instantiated incorrectly.
class ComponentInstantiationValidator: Processor {

    /// Initializer.
    ///
    /// - parameter components: The list of components that are parsed out.
    /// - parameter fileContents: The list of all parsed source files.
    init(components: [ASTComponent], fileContents: [String]) {
        self.componentNames = Set(components.map({ (component: ASTComponent) -> String in
            component.name
        }))
        self.fileContents = fileContents
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if any component instantiation is
    /// invalid.
    func process() throws {
        for content in fileContents {
            let matches = componentInstantiationRegex.matches(in: content)
            for match in matches {
                let componentName = content.substring(with: match.range(at: 1))
                if let componentName = componentName, componentNames.contains(componentName) {
                    let matchRange = match.range(at: 0)
                    // Use match range + 5 as the range to extract the argument.
                    // This includes one extra character after the expected `self`
                    // argument to check for cases such as `self.blah`.
                    let argRange = NSRange(location: matchRange.location + matchRange.length, length: 5)
                    let arg = content.substring(with: argRange)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    // Special case for root component, where it is instantiated
                    // with BootstrapComponent().
                    let rootArgRange = NSRange(location: matchRange.location + matchRange.length, length: 20)
                    let rootArg = content.substring(with: rootArgRange)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    if let arg = arg, !validate(componentInstantiationArg: arg, and: rootArg) {
                        throw GeneratorError.withMessage("\(componentName) is instantiated incorrectly. All components must be instantiated by parent components, by passing `self` as the argument to the parent parameter.")
                    }
                }
            }
        }
    }

    // MARK - Private

    private let componentNames: Set<String>
    private let fileContents: [String]

    private func validate(componentInstantiationArg arg: String, and rootArg: String?) -> Bool {
        return arg == "self" || arg == "self)" || arg == "self," || rootArg == "BootstrapComponent()"
    }
}
