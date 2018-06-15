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

import RxCocoa
import RxSwift
import SnapKit
import UIKit

public protocol ScoreSheetListener {
    func done()
}

public class ScoreSheetViewController: UIViewController {

    public var listener: ScoreSheetListener?

    init(scoreStream: ScoreStream) {
        self.scoreStream = scoreStream
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .blue

        buildScoreSheet()
        setupScoreStream()
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private let scoreStream: ScoreStream
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

    private func setupScoreStream() {
        guard let player1Score = player1Score, let player2Score = player2Score else { return }

        let initial = (PlayerScore(name: "None", score: 0), PlayerScore(name: "None", score: 0))

        scoreStream.scores
            .startWith(initial)
            .map { score1, _ in "\(score1.name) : \(score1.score)" }
            .bind(to: player1Score.rx.text)
            .disposed(by: disposeBag)

        scoreStream.scores
            .startWith(initial)
            .map { _, score2 in "\(score2.name) : \(score2.score)" }
            .bind(to: player2Score.rx.text)
            .disposed(by: disposeBag)
    }

    @objc
    private func didTapOkButton() {
        listener?.done()
    }
}
