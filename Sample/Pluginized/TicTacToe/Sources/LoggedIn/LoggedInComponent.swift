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
import ScoreSheet
import TicTacToeIntegrations
import UIKit

protocol LoggedInPluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder { get }
    var mutableScoreStream: MutableScoreStream { get }
}

class LoggedInComponent: PluginizedComponent<EmptyDependency, LoggedInPluginExtension, LoggedInNonCoreComponent>, LoggedInBuilder {

    var loggedInViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent,
                                      scoreStream: pluginExtension.mutableScoreStream,
                                      scoreSheetBuilder: pluginExtension.scoreSheetBuilder)
    }

    var gameComponent: GameComponent {
        return GameComponent(parent: self)
	}
}

// Use a builder protocol to allow mocking for unit tests. At the same time,
// this allows LoggedInViewController to be initialized lazily.
protocol LoggedInBuilder {
    var loggedInViewController: UIViewController { get }
}
