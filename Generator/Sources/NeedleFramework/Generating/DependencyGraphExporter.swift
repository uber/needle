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

enum DependencyGraphExporterError: Error {
    case timeout(String)
    case unableToWriteFile(String)
}

class DependencyGraphExporter {

    /// Initializer.
    init() {}

    func export(components: [Component], to path: String, using executor: SequenceExecutor) throws {
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

        let fileContents = serialize(providers: providers)

        do {
            try fileContents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw DependencyGraphExporterError.unableToWriteFile(path)
        }

    }

    private func serialize(providers: [SerializedDependencyProvider]) -> String {
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

        return """
        import NeedleFoundation

        // MARK: - Dependency Provider Factories

        func registerDependencyProviderFactories() {
            \(registrationBody)
        }

        // MARK: - Dependency Providers

        \(providersSection)
        """
    }
}
