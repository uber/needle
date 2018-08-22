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

class LoggedInViewController: ObservableViewController, ScoreSheetListener {

    private let gameBuilder: GameBuilder
    private let scoreStream: ScoreStream
    private var gameDisposable: Disposable?
    private let scoreSheetBuilder: ScoreSheetBuilder

    init(gameBuilder: GameBuilder, scoreStream: ScoreStream, scoreSheetBuilder: ScoreSheetBuilder) {
        self.gameBuilder = gameBuilder
        self.scoreStream = scoreStream
        self.scoreSheetBuilder = scoreSheetBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yellow

        let scoreButton = buildScoreButton()
        buildGameButton(with: scoreButton)
    }

    private func buildScoreButton() -> UIButton {
        let scoreButton = UIButton()
        view.addSubview(scoreButton)
        scoreButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.bottom.equalTo(self.view.snp.bottom).inset(30)
            maker.leading.trailing.equalTo(self.view).inset(40)
            maker.height.equalTo(50)
        }
        scoreButton.setTitle("High Scores", for: .normal)
        scoreButton.setTitleColor(UIColor.white, for: .normal)
        scoreButton.backgroundColor = UIColor.black
        scoreButton.addTarget(self, action: #selector(didTapScoreButton), for: .touchUpInside)
        return scoreButton
    }

    private func buildGameButton(with previousButton: UIView) {
        let gameButton = UIButton()
        view.addSubview(gameButton)
        gameButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.bottom.equalTo(previousButton.snp.top).offset(-20)
            maker.leading.trailing.equalTo(self.view).inset(40)
            maker.height.equalTo(50)
        }
        gameButton.setTitle("Play TicTacToe", for: .normal)
        gameButton.setTitleColor(UIColor.white, for: .normal)
        gameButton.backgroundColor = UIColor.black
        gameButton.addTarget(self, action: #selector(didTapGameButton), for: .touchUpInside)
    }

    @objc
    private func didTapScoreButton() {
        if let scoreSheetVC = scoreSheetBuilder.scoreSheetViewController as? ScoreSheetViewController {
            scoreSheetVC.listener = self
            present(scoreSheetVC, animated: true)
        }
    }

    @objc
    private func didTapGameButton() {
        let viewController = gameBuilder.gameViewController
        present(viewController, animated: true, completion: nil)

        gameDisposable?.dispose()
        gameDisposable = scoreStream.gameDidEnd
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                assert(self?.presentedViewController === viewController)
                self?.dismiss(animated: true, completion: nil)
            })
    }

    func done() {
        dismiss(animated: true)
    }

    deinit {
        gameDisposable?.dispose()
    }
}
