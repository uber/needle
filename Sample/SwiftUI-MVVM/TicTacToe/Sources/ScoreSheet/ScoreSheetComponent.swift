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

import NeedleFoundation
import SwiftUI

@MainActor
protocol ScoreSheetDependency: Dependency {
    var scoreStream: ScoreStream { get }
}

class ScoreSheetComponent: Component<ScoreSheetDependency>, ScoreSheetBuilder {

    var scoreSheetViewModel: ScoreSheetViewModel {
        ScoreSheetViewModel(
            scoreStream: dependency.scoreStream
        )
    }

    var scoreSheetView: AnyView {
        return AnyView(
            ScoreSheetView(
                viewModel: scoreSheetViewModel
            )
        )
    }
}

// Use a builder protocol to allow mocking for unit tests
@MainActor
protocol ScoreSheetBuilder {
    var scoreSheetView: AnyView { get }
}
