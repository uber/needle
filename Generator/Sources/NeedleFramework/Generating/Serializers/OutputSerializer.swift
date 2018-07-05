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
    init(providers: [SerializedProvider], imports: [String]) {
        self.providers = providers
        self.imports = imports
    }

    /// Serialize the data model into source code.
    ///
    /// - returns: The source code `String`.
    func serialize() -> String {
        let registrationBody = providers
            .map { (provider: SerializedProvider) in
                provider.registration
            }
            .joined()
            .replacingOccurrences(of: "\n", with: "\n    ")

        let providersSection = providers
            .map { (provider: SerializedProvider) in
                provider.content
            }
            .joined()

        let importsJoined = imports.joined(separator: "\n")

        return """
        \(importsJoined)

        // MARK: - Registration

        func registerProviderFactories() {
            \(registrationBody)
        }

        // MARK: - Providers

        \(providersSection)
        """
    }

    // MARK: - Private

    private let providers: [SerializedProvider]
    private let imports: [String]
}
