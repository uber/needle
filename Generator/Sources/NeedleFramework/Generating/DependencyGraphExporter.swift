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

/// Errors that may occur while trying to export the dependency provider classes.
enum DependencyGraphExporterError: Error {
    /// One of the dependecy provider tasks timed out, possibly due to some massive
    /// class or a programming error causing some sort of infinite loop
    /// String contains the name of the component.
    case timeout(String)
    /// Problem while trying to write the generated text to disk
    /// The String contains the file we were tyingto write to.
    case unableToWriteFile(String)
}

/// The generation phase entry class that executes tasks to process dependency
/// graph components into the necessary dependency providers and their registrations,
/// then exports the contents to the destination path.
class DependencyGraphExporter {

    /// Initializer.
    init() {}

    /// Given an array of components to create dependency providers for, for
    /// each one, traverse it's list of parents looking for all the required
    /// dependencies. Then turn this data into the source code for the dependency
    /// providers.
    ///
    /// - parameter components: Array of Components to export.
    /// - parameter imports: The import statements.
    /// - parameter to: Path to file where we want the results written to.
    /// - parameter using: The executor to use for concurrent computation of the
    ///   dependency provider bodies.
    /// - throws: `DependencyGraphExporterError.timeout` if computation times out.
    /// - throws: `DependencyGraphExporterError.unableToWriteFile` if the file write fails.
    func export(_ components: [Component], with imports: [String], to path: String, using executor: SequenceExecutor) throws {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<[SerializedDependencyProvider]>, componentName: String)]()

        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            let taskHandle = executor.execute(sequenceFrom: task)
            taskHandleTuples.append((taskHandle, component.name))
        }

        // Wait for all the generation to complete so we can write all the output into a single file
        var providers = [SerializedDependencyProvider]()
        for (taskHandle, compnentName) in taskHandleTuples {
            do {
                let provider = try taskHandle.await(withTimeout: 30)
                providers.append(contentsOf: provider)
            } catch SequenceExecutionError.awaitTimeout  {
                throw DependencyGraphExporterError.timeout(compnentName)
            } catch {
                fatalError("Unhandled task execution error \(error)")
            }
        }

        let fileContents = serialize(providers, with: imports)

        do {
            try fileContents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw DependencyGraphExporterError.unableToWriteFile(path)
        }
    }

    // MARK: - Private

    private func serialize(_ providers: [SerializedDependencyProvider], with imports: [String]) -> String {
        let registrationBody = providers
            .map { (provider: SerializedDependencyProvider) in
                provider.registration
            }
            .joined()
            .replacingOccurrences(of: "\n", with: "\n    ")

        let providersSection = providers
            .map { (provider: SerializedDependencyProvider) in
                provider.content
            }
            .joined()

        let importsJoined = imports.joined(separator: "\n")

        return """
        \(importsJoined)

        // MARK: - Dependency Provider Factories

        func registerDependencyProviderFactories() {
            \(registrationBody)
        }

        // MARK: - Dependency Providers

        \(providersSection)
        """
    }
}
