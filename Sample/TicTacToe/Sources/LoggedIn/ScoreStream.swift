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
import RxSwift

struct PlayerScore {
    let name: String
    let score: Int
}

protocol ScoreStream {
    var gameDidEnd: Observable<()> { get }
    var scores: Observable<(PlayerScore, PlayerScore)> { get }
}

protocol MutableScoreStream: ScoreStream {
    func updateDraw()
    func updateScore(withWinner winner: String, loser: String)
}

class ScoreStreamImpl: MutableScoreStream {

    private let updateSubject = PublishSubject<()>()
    private let scoreSubject = ReplaySubject<(PlayerScore, PlayerScore)>.create(bufferSize: 1)

    var gameDidEnd: Observable<()> {
        return updateSubject.asObservable()
    }

    var scores: Observable<(PlayerScore, PlayerScore)> {
        return scoreSubject
            .withPreviousValue()
            .map { (previous: (player1Score: PlayerScore, player2Score: PlayerScore)?, increment: (player1Score: PlayerScore, player2Score: PlayerScore)) -> (PlayerScore, PlayerScore) in
                if let previous = previous {
                    let player1Score = PlayerScore(name: previous.player1Score.name, score: (previous.player1Score.score + increment.player1Score.score))
                    let player2Score = PlayerScore(name: previous.player2Score.name, score: (previous.player2Score.score + increment.player2Score.score))
                    return (player1Score, player2Score)
                } else {
                    return increment
                }
            }
    }

    func updateDraw() {
        updateSubject.onNext(())
    }

    func updateScore(withWinner winner: String, loser: String) {
        let winner = PlayerScore(name: winner, score: 1)
        let loser = PlayerScore(name: loser, score: 0)
        scoreSubject.onNext((winner, loser))
        updateSubject.onNext(())
    }
}
