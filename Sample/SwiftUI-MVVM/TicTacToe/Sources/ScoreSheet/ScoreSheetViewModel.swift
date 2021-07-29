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

protocol ScoreSheetViewModelProtocol: ObservableObject {
    var player1Score: String { get }
    var player2Score: String { get }
}

final class ScoreSheetViewModel: ScoreSheetViewModelProtocol {
    private let scoreStream: ScoreStream
    private var cancellables = Set<AnyCancellable>()
    @Published var player1Score: String = "None : 0"
    @Published var player2Score: String = "None : 0"
    
    init(scoreStream: ScoreStream) {
        self.scoreStream = scoreStream
        setupScoreStream()
    }
    
    func setupScoreStream() {
        let initial = (
            PlayerScore(name: "None", score: 0),
            PlayerScore(name: "None", score: 0)
        )
        
        scoreStream.scores
            .prepend(initial)
            .map { score1, _ in
                "\(score1.name) : \(score1.score)"
            }
            .assign(to: \.player1Score, on: self)
            .store(in: &cancellables)
        
        scoreStream.scores
            .prepend(initial)
            .map { _, score2 in
                "\(score2.name) : \(score2.score)"
            }
            .assign(to: \.player2Score, on: self)
            .store(in: &cancellables)
    }
}
