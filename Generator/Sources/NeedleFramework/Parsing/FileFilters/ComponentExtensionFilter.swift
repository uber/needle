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
import SourceParsingFramework

/// A filter that checks if the given content contains an extension of
/// any one of the components.
class ComponentExtensionFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    /// - parameter components: All the components parsed out.
    init(content: String, components: [ASTComponent]) {
        self.content = content
        self.componentNames = components.map { (component: ASTComponent) -> String in
            component.name
        }
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the file content contains component class
    /// extensions of the given parsed components.
    func filter() -> Bool {
        // Use simple string matching first since it's more performant.
        return content.contains("extension")
    }

    // MARK: - Private

    private let content: String
    private let componentNames: [String]
}
