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

// Use a builder protocol to allow mocking for unit tests. At the same time,
// this allows LoggedOutViewController to be initialized lazily.
protocol LoggedOutBuilder {
    var loggedOutViewController: UIViewController { get }
}

extension RootComponent: LoggedOutBuilder {
    var loggedOutViewController: UIViewController {
        return loggedOutComponent.loggedOutViewController
    }
}

class RootViewController: UIViewController {

    private let playersStream: PlayersStream
    private let loggedOutBuilder: LoggedOutBuilder
    private var loginDisposable: Disposable?

    init(playersStream: PlayersStream, loggedOutBuilder: LoggedOutBuilder) {
        self.playersStream = playersStream
        self.loggedOutBuilder = loggedOutBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentLoggedOut()
    }

    private func presentLoggedOut() {
        present(loggedOutBuilder.loggedOutViewController, animated: true, completion: nil)

        loginDisposable?.dispose()
        loginDisposable = playersStream.names
            .subscribe(onNext: { (player1: String, player2: String) in
                print("\(player1), \(player2)")
            })
    }
}
