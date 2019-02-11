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
import UIKit

class LoggedInComponent: Component<EmptyDependency>, LoggedInBuilder {

    var scoreStream: ScoreStream {
        return mutableScoreStream
    }

    var loggedInViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent, scoreStream: scoreStream, scoreSheetBuilder: scoreSheetComponent)
    }

    var gameComponent: GameComponent {
        return GameComponent(parent: self)
	}

    var scoreSheetComponent: ScoreSheetComponent {
        return ScoreSheetComponent(parent: self)
    }
}

// Use a builder protocol to allow mocking for unit tests. At the same time,
// this allows LoggedInViewController to be initialized lazily.
protocol LoggedInBuilder {
    var loggedInViewController: UIViewController { get }
}

// Use extension to show parsing of component extensions.
extension LoggedInComponent {

    var mutableScoreStream: MutableScoreStream {
        return shared { ScoreStreamImpl() }
    }
}
