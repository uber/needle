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

/// The generation phase entry class that executes tasks to process dependency
/// graph components, inlcuding pluginized and non-core ones, into necessary
/// dependency providers and their registrations, then exports the contents to
/// the destination path.
class PluginizedDependencyGraphExporter {

    /// Generate the necessary dependency provider and plugin extension source
    /// code for the given components and pluginized components, and export
    /// the source code to the given destination path.
    ///
    /// - parameter components: Array of Components to generate dependnecy
    /// providers for
    /// - parameter pluginizedComponents: Array of pluginized components to
    /// generate plugin extensions and dependnecy providers for.
    /// - parameter imports: The import statements.
    /// - parameter path: Path to file where we want the results written to.
    /// - parameter executor: The executor to use for concurrent computation of
    /// the dependency provider bodies.
    /// - parameter timeout: The timeout value, in seconds, to use for
    /// waiting on exporting tasks.
    /// - parameter headerDocPath: The path to custom header doc file to be
    /// included at the top of the generated file.
    /// - parameter needleVersionHash: The needleVersionHash so that we
    /// can recompile when upstream-dependency files change
    /// - throws: `DependencyGraphExporterError.timeout` if computation times out.
    /// - throws: `DependencyGraphExporterError.unableToWriteFile` if the file
    /// write fails.
    func export(_ components: [Component], _ pluginizedComponents: [PluginizedComponent], with imports: [String], to path: String, using executor: SequenceExecutor, withTimeout timeout: TimeInterval, include headerDocPath: String?, needleVersionHash: String?) throws {
        // Enqueue tasks.
        let dependencyProviderHandleTuples = enqueueExportDependencyProviders(for: components, pluginizedComponents, using: executor)
        let pluginExtensionHandleTuples = enqueueExportPluginExtensions(for: pluginizedComponents, using: executor)
        let headerDocContentHandle = enqueueLoadHeaderDoc(from: headerDocPath, using: executor)

        // Wait for execution to complete.
        let serializedProviders = try awaitSerialization(using: dependencyProviderHandleTuples + pluginExtensionHandleTuples, withTimeout: timeout)
        let headerDocContent = try headerDocContentHandle?.await(withTimeout: timeout) ?? ""

        let fileContents = OutputSerializer(providers: serializedProviders, imports: imports, headerDocContent: headerDocContent, needleVersionHash: needleVersionHash).serialize()
        let currentFileContents = try? String(contentsOfFile: path, encoding: .utf8)
        guard currentFileContents != fileContents else {
            info("Not writing the file as content is unchanged")
            return
        }
        try fileContents.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func enqueueLoadHeaderDoc(from filePath: String?, using executor: SequenceExecutor) -> SequenceExecutionHandle<String>? {
        guard let filePath = filePath else {
            return nil
        }
        let loaderTask = FileContentLoaderTask(filePath: filePath)
        return executor.executeSequence(from: loaderTask) { (_, result: Any) -> SequenceExecution<String> in
            // Cannot throw error here. Also the force cast is safe since that's
            // the return type of the task.
            return .endOfSequence(result as! String)
        }
    }

    private func enqueueExportDependencyProviders(for components: [Component], _ pluginizedComponents: [PluginizedComponent], using executor: SequenceExecutor) -> [(SequenceExecutionHandle<[SerializedProvider]>, String)] {
        let pluginizedData = pluginizedComponents.map { (component: PluginizedComponent) -> Component in
            component.data
        }
        let allComponents = components + pluginizedData

        var taskHandleTuples = [(handle: SequenceExecutionHandle<[SerializedProvider]>, componentName: String)]()
        for component in allComponents {
            let initialTask = DependencyProviderDeclarerTask(component: component)
            let taskHandle = executor.executeSequence(from: initialTask) { (currentTask: Task, currentResult: Any) -> SequenceExecution<[SerializedProvider]> in
                if currentTask is DependencyProviderDeclarerTask, let providers = currentResult as? [DependencyProvider] {
                    return .continueSequence(PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents))
                } else if currentTask is PluginizedDependencyProviderContentTask, let processedProviders = currentResult as? [PluginizedProcessedDependencyProvider] {
                    return .continueSequence(PluginizedDependencyProviderSerializerTask(providers: processedProviders))
                } else if currentTask is PluginizedDependencyProviderSerializerTask, let serializedProviders = currentResult as? [SerializedProvider] {
                    return .endOfSequence(serializedProviders)
                } else {
                    error("Unhandled task \(currentTask) with result \(currentResult)")
                }
            }
            taskHandleTuples.append((taskHandle, component.name))
        }

        return taskHandleTuples
    }

    private func enqueueExportPluginExtensions(for pluginizedComponents: [PluginizedComponent], using executor: SequenceExecutor) -> [(SequenceExecutionHandle<[SerializedProvider]>, String)] {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<[SerializedProvider]>, pluginExtensionName: String)]()
        for component in pluginizedComponents {
            let task = PluginExtensionSerializerTask(component: component)
            let taskHandle = executor.executeSequence(from: task) { (currentTask: Task, currentResult: Any) -> SequenceExecution<[SerializedProvider]> in
                return .endOfSequence([currentResult as! SerializedProvider])
            }
            taskHandleTuples.append((taskHandle, component.pluginExtension.name))
        }

        return taskHandleTuples
    }

    private func awaitSerialization(using taskHandleTuples: [(SequenceExecutionHandle<[SerializedProvider]>, String)], withTimeout timeout: TimeInterval) throws -> [SerializedProvider] {
        var providers = [SerializedProvider]()
        var isMissingDependencies = false
        for (taskHandle, componentName) in taskHandleTuples {
            do {
                let provider = try taskHandle.await(withTimeout: timeout)
                providers.append(contentsOf: provider)
            } catch DependencyProviderContentError.missingDependency(let message) {
                warning(message)
                isMissingDependencies = true
            } catch SequenceExecutionError.awaitTimeout  {
                throw GenericError.withMessage("Generating dependency provider for \(componentName) timed out.")
            } catch {
                throw error
            }
        }
        if isMissingDependencies {
            throw GenericError.withMessage("Some dependencies are missing, please look at the warnings above for the list.")
        }
        return providers
    }
}
