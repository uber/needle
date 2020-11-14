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

import SnapKit
import UIKit

protocol ScoreSheetListener {
    func done()
}

class ScoreSheetViewController: UIViewController {

    public var listener: ScoreSheetListener?

    init(scoreStore: ScoreStore) {
        self.scoreStore = scoreStore
        super.init(nibName: nil, bundle: nil)
        
        scoreStore.add(listener: self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .blue

        buildScoreSheet()
        setupInitialValue()
    }

    // MARK: - Private
    private let scoreStore: ScoreStore
    private var player1Score: UILabel?
    private var player2Score: UILabel?
    private var okButton: UIButton?

    private func buildScoreSheet() {
        let player1Score = UILabel()
        self.player1Score = player1Score
        player1Score.backgroundColor = .lightGray
        view.addSubview(player1Score)
        player1Score.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.height.equalTo(44)
            maker.top.equalTo(view).offset(100)
            maker.leading.equalTo(view).offset(50)
            maker.trailing.equalTo(view).offset(-50)
        }

        let player2Score = UILabel()
        self.player2Score = player2Score
        player2Score.backgroundColor = .lightGray
        view.addSubview(player2Score)
        player2Score.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.height.equalTo(player1Score)
            maker.top.equalTo(player1Score.snp.bottom).offset(20)
            maker.leading.trailing.equalTo(player1Score)
        }

        let okButton = UIButton()
        self.okButton = okButton
        okButton.backgroundColor = .black
        view.addSubview(okButton)
        okButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.height.equalTo(44)
            maker.width.equalTo(100)
            maker.bottom.equalTo(view).offset(-50)
            maker.centerX.equalTo(view)
        }

        okButton.setTitle("OK", for: .normal)
        okButton.setTitleColor(.white, for: .normal)
        okButton.addTarget(self, action: #selector(didTapOkButton), for: .touchUpInside)
    }

    private func setupInitialValue() {
        updateScore(player1Score: scoreStore.scores.0, player2Score: scoreStore.scores.1)
    }

    @objc
    private func didTapOkButton() {
        listener?.done()
    }
    
    deinit {
        scoreStore.remove(listener: self)
    }
}

extension ScoreSheetViewController: ScoreStatusListener {
    func gameDidEnd() {}
    
    func scoreUpdated(player1Score: PlayerScore, player2Score: PlayerScore) {
        updateScore(player1Score: player1Score, player2Score: player2Score)
    }
    
    private func updateScore(player1Score: PlayerScore, player2Score: PlayerScore) {
        self.player1Score?.text = "\(player1Score.name): \(player1Score.score)"
        self.player2Score?.text = "\(player2Score.name): \(player2Score.score)"
    }
}
