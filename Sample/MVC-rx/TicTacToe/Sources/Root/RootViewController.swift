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
import UIKit

private enum RootChildStates {
    case loggedOut
    case loggedIn
}

class RootViewController: UIViewController {

    private let playersStream: PlayersStream
    private let loggedOutBuilder: LoggedOutBuilder
    private let loggedInBuilder: LoggedInBuilder
    private var playersStreamDisposable: Disposable?

    init(playersStream: PlayersStream, loggedOutBuilder: LoggedOutBuilder, loggedInBuilder: LoggedInBuilder) {
        self.playersStream = playersStream
        self.loggedOutBuilder = loggedOutBuilder
        self.loggedInBuilder = loggedInBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateChildViewController()
    }

    private func updateChildViewController() {
        if playersStreamDisposable != nil {
            return
        }

        playersStreamDisposable = playersStream.names
            .map { (names: (String, String)?) in
                names == nil ? RootChildStates.loggedOut : RootChildStates.loggedIn
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (state: RootChildStates) in
                guard let strongSelf = self else {
                    return
                }

                switch state {
                case .loggedIn:
                    strongSelf.present(viewController: strongSelf.loggedInBuilder.loggedInViewController)
                case .loggedOut:
                    strongSelf.present(viewController: strongSelf.loggedOutBuilder.loggedOutViewController)
                }
            })
    }

    private func present(viewController: UIViewController) {
        if presentedViewController == viewController {
            return
        }

        if presentedViewController != nil {
            dismiss(animated: true) {
                self.present(viewController, animated: true, completion: nil)
            }
        } else {
            present(viewController, animated: true, completion: nil)
        }
    }

    deinit {
        playersStreamDisposable?.dispose()
    }
}
