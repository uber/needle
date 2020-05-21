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

import RxSwift
import ScoreSheet
import SnapKit
import UIKit

private let rowCount = 3
private let colCount = 3
private let sectionCount = 1
private let cellSize: CGFloat = UIScreen.main.bounds.width / CGFloat(colCount)
private let cellIdentifier = "TicTacToeCell"

private enum Players: Int {
    case player1 = 1
    case player2

    var color: UIColor {
        switch self {
        case .player1:
            return UIColor.red
        case .player2:
            return UIColor.blue
        }
    }
}

class GameViewController: ObservableViewController, UICollectionViewDataSource, UICollectionViewDelegate, ScoreSheetListener {

    private let mutableScoreStream: MutableScoreStream
    private let playersStream: PlayersStream
    private let scoreSheetBuilder: ScoreSheetBuilder
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: cellSize, height: cellSize)
        return UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    }()
    private var appearanceDisposable = CompositeDisposable()

    init(mutableScoreStream: MutableScoreStream, playersStream: PlayersStream, scoreSheetBuilder: ScoreSheetBuilder) {
        self.mutableScoreStream = mutableScoreStream
        self.playersStream = playersStream
        self.scoreSheetBuilder = scoreSheetBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.purple

        buildCollectionView()
        buildScoerButton()
        initBoard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        appearanceDisposable.dispose()
        appearanceDisposable = CompositeDisposable()
    }

    private func buildCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.center.equalTo(self.view.snp.center)
            maker.size.equalTo(CGSize(width: CGFloat(colCount) * cellSize, height: CGFloat(rowCount) * cellSize))
        }
    }

    private func announce(_ winner: Players, withCompletionHandler handler: @escaping () -> ()) {
        performOnPlayerNames { [weak self] (player1Name: String, player2Name: String) in
            let winnerName: String
            switch winner {
            case .player1:
                winnerName = player1Name
            case .player2:
                winnerName = player2Name
            }
            self?.showAlert(with: "\(winnerName) Won!", completionHandler: handler)
        }
    }

    private func announceDraw(withCompletionHandler handler: @escaping () -> ()) {
        showAlert(with: "It's a Tie", completionHandler: handler)
    }

    private func showAlert(with title: String, completionHandler handler: @escaping () -> ()) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close Game", style: UIAlertAction.Style.default) { _ in
            handler()
        }
        alert.addAction(closeAction)
        present(alert, animated: true, completion: nil)
    }

    private func performOnPlayerNames(with handler: @escaping (String, String) -> ()) {
        let disposable = playersStream.names
            .take(1)
            .flatMap { (names: (String, String)?) -> Observable<(String, String)> in
                if let names = names {
                    return Observable.just(names)
                } else {
                    return Observable.never()
                }
            }
            .subscribe(onNext: { (player1Name: String, player2Name: String) in
                handler(player1Name, player2Name)
            })
        _ = appearanceDisposable.insert(disposable)
    }

    // MARK: - High Scores

    private func buildScoerButton() {
        let scoreButton = UIButton()
        view.addSubview(scoreButton)
        scoreButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.bottom.equalTo(self.view.snp.bottom).offset(-70)
            maker.leading.trailing.equalTo(self.view).inset(40)
            maker.height.equalTo(50)
        }
        scoreButton.setTitle("High Scores", for: .normal)
        scoreButton.setTitleColor(UIColor.white, for: .normal)
        scoreButton.backgroundColor = UIColor.black
        scoreButton.addTarget(self, action: #selector(didTapScoreButton), for: .touchUpInside)
    }

    @objc
    private func didTapScoreButton() {
        if let scoreSheetVC = scoreSheetBuilder.scoreSheetViewController as? ScoreSheetViewController {
            scoreSheetVC.listener = self
            present(scoreSheetVC, animated: true)
        }
    }

    func done() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Game Logic

    private var currentPlayer = Players.player1
    private var board = [[Players?]]()

    private func initBoard() {
        for _ in 0 ..< rowCount {
            board.append([nil, nil, nil])
        }
    }

    private func placeCurrentPlayerMark(at row: Int, col: Int) {
        guard board[row][col] == nil else {
            return
        }

        let currentPlayer = getAndFlipCurrentPlayer()
        board[row][col] = currentPlayer
        setCell(at: row, col: col, withPlayerType: currentPlayer)

        let endGame = checkEndGame()
        if endGame.didEnd {
            if let winner = endGame.winner {
                performOnPlayerNames { [weak self] (player1Name: String, player2Name: String) in
                    let winnerName = winner == .player1 ? player1Name : player2Name
                    let loserName = winner != .player1 ? player1Name : player2Name
                    self?.announce(winner) { [weak self] in
                        self?.mutableScoreStream.updateScore(withWinner: winnerName, loser: loserName)
                    }
                }
            } else {
                announceDraw { [weak self] in
                    self?.mutableScoreStream.updateDraw()
                }
            }
        }
    }

    private func setCell(at row: Int, col: Int, withPlayerType playerType: Players) {
        let indexPathRow = row * colCount + col
        let cell = collectionView.cellForItem(at: IndexPath(row: indexPathRow, section: sectionCount - 1))
        cell?.backgroundColor = playerType.color
    }

    private func getAndFlipCurrentPlayer() -> Players {
        let currentPlayer = self.currentPlayer
        self.currentPlayer = currentPlayer == .player1 ? .player2 : .player1
        return currentPlayer
    }

    private func checkEndGame() -> (winner: Players?, didEnd: Bool) {
        let winner = checkWinner()
        if let winner = winner {
            return (winner, true)
        }
        let isDraw = checkDraw()
        if isDraw {
            return (nil, true)
        }

        return (nil, false)
    }

    private func checkWinner() -> Players? {
        // Rows.
        for row in 0 ..< rowCount {
            guard let assumedWinner = board[row][0] else {
                continue
            }
            var winner: Players? = assumedWinner
            for col in 1 ..< colCount {
                if assumedWinner.rawValue != board[row][col]?.rawValue {
                    winner = nil
                    break
                }
            }
            if let winner = winner {
                return winner
            }
        }

        // Cols.
        for col in 0 ..< colCount {
            guard let assumedWinner = board[0][col] else {
                continue
            }
            var winner: Players? = assumedWinner
            for row in 1 ..< rowCount {
                if assumedWinner.rawValue != board[row][col]?.rawValue {
                    winner = nil
                    break
                }
            }
            if let winner = winner {
                return winner
            }
        }

        // Diagnals.
        guard let p11 = board[1][1] else {
            return nil
        }
        if let p00 = board[0][0], let p22 = board[2][2] {
            if p00.rawValue == p11.rawValue && p11.rawValue == p22.rawValue {
                return p11
            }
        }

        if let p02 = board[0][2], let p20 = board[2][0] {
            if p02.rawValue == p11.rawValue && p11.rawValue == p20.rawValue {
                return p11
            }
        }

        return nil
    }

    private func checkDraw() -> Bool {
        for row in 0 ..< rowCount {
            for col in 0 ..< colCount {
                if board[row][col] == nil {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rowCount * colCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusedCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        reset(cell: reusedCell)
        return reusedCell
    }

    private func reset(cell: UICollectionViewCell) {
        cell.backgroundColor = UIColor.white
        cell.contentView.layer.borderWidth = 2
        cell.contentView.layer.borderColor = UIColor.lightGray.cgColor
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row / colCount
        let col = indexPath.row - row * rowCount
        placeCurrentPlayerMark(at: row, col: col)
    }
}
