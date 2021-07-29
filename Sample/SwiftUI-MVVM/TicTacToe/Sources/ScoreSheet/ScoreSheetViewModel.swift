//
//  ScoreSheetViewModel.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/28/21.
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
