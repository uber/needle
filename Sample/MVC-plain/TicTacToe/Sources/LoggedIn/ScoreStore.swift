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

struct PlayerScore {
    let name: String
    var score: Int
}

protocol ScoreStatusListener: class {
    func gameDidEnd()
    func scoreUpdated(player1Score: PlayerScore, player2Score: PlayerScore)
}

protocol ScoreStore {
    var scores: (PlayerScore, PlayerScore) { get }
    func add(listener: ScoreStatusListener)
    func remove(listener: ScoreStatusListener)
}

protocol MutableScoreStore: ScoreStore {
    func updateDraw()
    func updateScore(withWinner winner: String, loser: String)
}

class ScoreStoreImpl: MutableScoreStore {
    private var listeners: [ScoreStatusListener]  = []

    private var player1Score: PlayerScore?
    private var player2Score: PlayerScore?

    var scores: (PlayerScore, PlayerScore) {
        if let player1Score = player1Score, let player2Score = player2Score {
            return (player1Score, player2Score)
        } else {
            return (PlayerScore(name: "None", score: 0), PlayerScore(name: "None", score: 0))
        }
    }

    func updateDraw() {
        listeners.forEach { $0.gameDidEnd() }
    }

    func updateScore(withWinner winner: String, loser: String) {
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

        listeners.forEach { $0.scoreUpdated(player1Score: scores.0, player2Score: scores.1) }
        listeners.forEach { $0.gameDidEnd() }
    }
    
    func add(listener: ScoreStatusListener) {
        let listenerAlreadyExists = listeners.contains { $0 === listener }
        if listenerAlreadyExists {
            return
        }
        
        listeners.append(listener)
    }
    
    func remove(listener: ScoreStatusListener) {
        let index = listeners.firstIndex { $0 === listener }
        if let index = index {
            listeners.remove(at: index)
        }
    }
}
