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

/// A utility class that serializes a set of providers and necessary
/// import statements into the final output file content.
class OutputSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter providers: The list of providers to output.
    /// - parameter imports: The list of import statements to include.
    /// - parameter headerDocContent: The content of the header doc to
    /// include at the top of the output file.
    init(providers: [SerializedProvider], imports: [String], headerDocContent: String, needleVersionHash: String? = nil) {
        self.providers = providers
        self.imports = imports
        self.headerDocContent = headerDocContent
        self.needleVersionHash = needleVersionHash
    }

    /// Serialize the data model into source code.
    ///
    /// - returns: The source code `String`.
    func serialize() -> String {
        // Dependency factories have deterministic names, so we can only define a
        // factory once, or the code won't compile.
        var registeredFactories: Set<String> = []
        // We generate parent traversal functions to improve compile time on large
        // codebases. This tells us how many levels deep the tree goes.
        var maxLevel: Int = 1

        let providersSection = providers
            .map { (provider: SerializedProvider) in
                if let providerMaxLevel = provider.attributes.maxLevel {
                    if providerMaxLevel > maxLevel {
                        maxLevel = providerMaxLevel
                    }
                }
                if let factoryName = provider.attributes.factoryName {
                    if registeredFactories.contains(factoryName) {
                        return ""
                    }
                    registeredFactories.insert(factoryName)
                }
                return provider.content
            }
            .joined()

        let traversalHelpers = (1...maxLevel).map { num in
            return """
            private func parent\(num)(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
                return component\(String(repeating: ".parent", count: num))
            }
            """
        }.joined(separator: "\n\n")
        
        let needleDependenciesHash = needleVersionHash.map { return "\"\($0)\""} ?? "nil"

        let importsJoined = imports.joined(separator: "\n")

        // With Swift 5.6 and an amd64 target, having a function body that is
        // thousands of lines long causes a severe compile performance
        // regression. We were seeing compilation take 4.5x what an x86_64
        // target would take. As a result, this code splits the calls to
        // register the dependencies into functions around 50 lines long.
        // Through some basic testing, this seemed to produce the best results.
        let linesPerHelper = 50
        var registrationHelperFuncs: [String] = []
        let registrations: [String] = providers
            .map { (provider: SerializedProvider) in
                provider.registration
            }
            .filter {
                !$0.isEmpty
            }
        let registrationBody = stride(from: 0, to: registrations.count, by: linesPerHelper)
            .map {
                let helperBody = registrations[$0 ..< Swift.min($0 + linesPerHelper, registrations.count)]
                    .joined()
                    .replacingOccurrences(of: "\n", with: "\n    ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let regNum = ($0 / linesPerHelper) + 1
                registrationHelperFuncs.append("""
                private func register\(regNum)() {
                    \(helperBody)
                }
                """)
                return "register\(regNum)()"
            }
            .joined(separator: "\n    ")
        let registrationHelpers = registrationHelperFuncs.joined(separator: "\n\n")

        return """
        \(headerDocContent)

        \(importsJoined)
        
        // swiftlint:disable unused_declaration
        private let needleDependenciesHash : String? = \(needleDependenciesHash)

        // MARK: - Traversal Helpers

        \(traversalHelpers)

        // MARK: - Providers

        \(providersSection)

        private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
            return EmptyDependencyProvider(component: component)
        }

        // MARK: - Registration
        private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
            __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
        }

        \(registrationHelpers)

        public func registerProviderFactories() {
            \(registrationBody)
        }

        """
    }

    // MARK: - Private

    private let providers: [SerializedProvider]
    private let imports: [String]
    private let headerDocContent: String
    private let needleVersionHash: String?
}
