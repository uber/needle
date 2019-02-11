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

/// A list of IDs of task types used in the generator.
enum TaskIds: Int {
    /// File filtering task IDs.
    case declarationsFilterTask = 1
    case pluginizedDeclarationsFilterTask = 2
    case componentExtensionsFilterTask = 13
    case componentInitsFilterTask = 14
    /// File content loading task ID.
    case fileContentLoaderTask = 3
    /// AST producing task ID.
    case astProducerTask = 4
    /// AST parsing task IDs.
    case declarationsParserTask = 5
    case componentExtenionsParserTask = 15
    case pluginizedDeclarationsParserTask = 6
    /// Dependency provider declaring task ID.
    case dependencyProviderDeclarerTask = 7
    /// Dependency provider content task IDs.
    case dependencyProviderContentTask = 8
    case pluginizedDependencyProviderContentTask = 9
    /// Dependency provider serialization task IDs.
    case dependencyProviderSerializerTask = 10
    case pluginizedDependencyProviderSerializerTask = 11
    /// Plugin extension serialization task ID.
    case pluginExtensionSerializerTask = 12
}
