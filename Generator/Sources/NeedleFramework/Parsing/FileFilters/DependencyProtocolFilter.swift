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

/// A filter that performs checks if the file content contains any
/// dependency protocol declarations.
class DependencyProtocolFilter: KeywordRegexFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    init(content: String) {
        super.init(content: content, keyword: "Dependency", regex: Regex.foundationInheritanceRegex(forProtocol: "Dependency"))
    }
}
