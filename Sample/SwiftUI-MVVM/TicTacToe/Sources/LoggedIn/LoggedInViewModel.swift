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
import Combine

protocol LoggedInViewModelProtocol: ObservableObject {
    var selection: String? { get set }
    func gameTapped()
    func scoreTapped()
}

final class LoggedInViewModel: LoggedInViewModelProtocol {
    private let scoreStream: ScoreStream
    private var gameCancellable: Cancellable?
    @Published var selection: String? = nil
    
    init(scoreStream: ScoreStream) {
        self.scoreStream = scoreStream
    }
    
    func scoreTapped() {
        selection = Screen.score.rawValue
    }
    
    func gameTapped() {
        selection = Screen.game.rawValue
        gameCancellable?.cancel()
        gameCancellable = scoreStream.gameDidEnd
            .prefix(1)
            .sink(receiveValue: { _ in
                // TODO: dismiss
            })
    }
    
    deinit {
        gameCancellable?.cancel()
    }
}
