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
import SourceKittenFramework

class FileParser {
    private let file: File
    private let path: String
    private let componentsExpression = Regex("^Component *<(.+)>$")

    init(contents: String, path: String) {
        self.file = File(contents: contents)
        self.path = path
    }

    func parse() -> ([Component], [Dependency])? {
//        let result = try? Structure(file: file)
//
//        if let result = result {
//            let substructure = result.dictionary.substructure
//
//            // Find component subclasses
//            let components: [Component] = substructure.compactMap { structure in
//                if let kind = structure.kind, SwiftDeclarationKind(rawValue: kind) == .class {
//                    return parseClass(structure, filePath: path)
//                } else {
//                    return nil
//                }
//            }
//            let dependencyNames = components.map { $0.dependency }
//
//            // Scan for dependency protocols using the list generated above
//            let dependencies: [Dependency] = substructure.compactMap { structure in
//                if let name = structure.name, let kind = structure.kind, SwiftDeclarationKind(rawValue: kind) == .protocol {
//                    if dependencyNames.contains(name) {
//                        return parseProtocol(structure, filePath: path)
//                    }
//                }
//                return nil
//            }
//            return (components, dependencies)
//        }

        return nil
    }
}
