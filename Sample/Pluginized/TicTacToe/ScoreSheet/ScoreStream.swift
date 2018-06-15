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

public struct PlayerScore {
    let name: String
    var score: Int
}

public protocol ScoreStream {
    var gameDidEnd: Observable<()> { get }
    var scores: Observable<(PlayerScore, PlayerScore)> { get }
}

public protocol MutableScoreStream: ScoreStream {
    func updateDraw()
    func updateScore(withWinner winner: String, loser: String)
}

public class ScoreStreamImpl: MutableScoreStream {

    private let updateSubject = PublishSubject<()>()
    private let scoreSubject = ReplaySubject<(PlayerScore, PlayerScore)>.create(bufferSize: 1)

    private var player1Score: PlayerScore?
    private var player2Score: PlayerScore?

    public init() {}

    public var scores: Observable<(PlayerScore, PlayerScore)> {
        return scoreSubject
            .asObservable()
    }

    public var gameDidEnd: Observable<()> {
        return updateSubject.asObservable()
    }

    public func updateDraw() {
        updateSubject.onNext(())
    }

    public func updateScore(withWinner winner: String, loser: String) {
        if var player1Score = player1Score, var player2Score = player2Score {
            if winner == player1Score.name {
                player1Score.score += 1
            } else {
                player2Score.score += 1
            }
            self.player1Score = player1Score
            self.player2Score = player2Score
        } else {
            player1Score = PlayerScore(name: winner, score: 1)
            player2Score = PlayerScore(name: loser, score: 0)
        }

        scoreSubject.onNext((player1Score!, player2Score!))
        updateSubject.onNext(())
    }
}
