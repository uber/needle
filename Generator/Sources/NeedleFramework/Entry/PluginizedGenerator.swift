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

/// The entry point to Needle's code generator that supports plugins.
public class PluginizedGenerator: Generator {

    // MARK: - Internal

    override func generate(from sourceRootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, using executor: SequenceExecutor, withParsingTimeout parsingTimeout: TimeInterval, exportingTimeout: TimeInterval) throws {
        let parser = PluginizedDependencyGraphParser()
        let (components, pluginizedComponents, imports, needleVersionHash) = try parser.parse(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor, withTimeout: parsingTimeout)
        let exporter = PluginizedDependencyGraphExporter()
        try exporter.export(components, pluginizedComponents, with: imports + additionalImports, to: destinationPath, using: executor, withTimeout: exportingTimeout, include: headerDocPath, needleVersionHash: needleVersionHash)
    }
}
