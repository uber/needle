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
import SourceParsingFramework

typealias UrlFileContent = (url: URL, content: String)

/// A post processing utility class that checks if any components are
/// instantiated incorrectly.
class ComponentInstantiationValidator: Processor {

    /// Initializer.
    ///
    /// - parameter components: The list of components that are parsed out.
    /// - parameter fileContents: The list of all parsed source files.
    /// - parameter executor: The execution to use for executing validation
    /// tasks.
    /// - parameter timeout: The timeout value to use to wait for each
    /// individual validations.
    init(components: [ASTComponent], urlFileContents: [UrlFileContent], executor: SequenceExecutor, timeout: TimeInterval) {
        self.componentNames = Set(components.map({ (component: ASTComponent) -> String in
            component.name
        }))
        self.urlFileContents = urlFileContents
        self.executor = executor
        self.timeout = timeout
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if any component instantiation is
    /// invalid.
    func process() throws {
        // Enqueue validation tasks.
        var handles = [SequenceExecutionHandle<ComponentInstantiationValidationResult>]()
        for urlFileContent in urlFileContents {
            let task = ComponentInstantiationValidationTask(urlFileContent: urlFileContent, componentNames: componentNames)
            let handle = executor.executeSequence(from: task) { (_, result: Any) -> SequenceExecution<ComponentInstantiationValidationResult> in
                SequenceExecution.endOfSequence(result as! ComponentInstantiationValidationResult)
            }
            handles.append(handle)
        }

        // Process validation results.
        for handle in handles {
            let result = try handle.await(withTimeout: timeout)
            switch result {
            case .success:
                break
            case .failure(let url, let componentName):
                throw GenericError.withMessage("\(componentName) is instantiated incorrectly in \(url). All components must be instantiated by parent components, by passing `self` as the argument to the parent parameter.")
            }
        }
    }

    // MARK - Private

    private let componentNames: Set<String>
    private let urlFileContents: [UrlFileContent]
    private let executor: SequenceExecutor
    private let timeout: TimeInterval
}

private enum ComponentInstantiationValidationResult {
    case success
    case failure(URL, String)
}

private class ComponentInstantiationValidationTask: AbstractTask<ComponentInstantiationValidationResult> {

    fileprivate init(urlFileContent: UrlFileContent, componentNames: Set<String>) {
        self.urlFileContent = urlFileContent
        self.componentNames = componentNames
    }

    fileprivate override func execute() throws -> ComponentInstantiationValidationResult {
        let matches = componentInstantiationRegex.matches(in: urlFileContent.content)
        for match in matches {
            let componentName = urlFileContent.content.substring(with: match.range(at: 1))
            if let componentName = componentName, componentNames.contains(componentName) {
                let matchRange = match.range(at: 0)
                // Use match range + 5 as the range to extract the argument.
                // This includes one extra character after the expected `self`
                // argument to check for cases such as `self.blah`.
                let argRange = NSRange(location: matchRange.location + matchRange.length, length: 5)
                let arg = urlFileContent.content.substring(with: argRange)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                // Special case for root component, where it is instantiated
                // with BootstrapComponent().
                let rootArgRange = NSRange(location: matchRange.location + matchRange.length, length: 20)
                let rootArg = urlFileContent.content.substring(with: rootArgRange)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                if let arg = arg, !validate(componentInstantiationArg: arg, and: rootArg) {
                    return .failure(urlFileContent.url, componentName)
                }
            }
        }

        return .success
    }

    // MARK: - Private

    private let urlFileContent: UrlFileContent
    private let componentNames: Set<String>

    private func validate(componentInstantiationArg arg: String, and rootArg: String?) -> Bool {
        return arg == "self" || arg == "self)" || arg == "self," || rootArg == "BootstrapComponent()"
    }
}
