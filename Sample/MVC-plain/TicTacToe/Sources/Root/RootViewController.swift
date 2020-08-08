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

import UIKit

class RootViewController: UIViewController {

    private let playersStore: PlayersStore
    private let loggedOutBuilder: LoggedOutBuilder
    private let loggedInBuilder: LoggedInBuilder

    init(playersStore: PlayersStore, loggedOutBuilder: LoggedOutBuilder, loggedInBuilder: LoggedInBuilder) {
        self.playersStore = playersStore
        self.loggedOutBuilder = loggedOutBuilder
        self.loggedInBuilder = loggedInBuilder
        super.init(nibName: nil, bundle: nil)
        
        self.playersStore.add(listener: self)
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

        updateChildViewController(names: nil)
    }

    private func updateChildViewController(names: (String, String)?) {
        if names == nil {
            present(viewController: loggedOutBuilder.loggedOutViewController)
        } else  {
            present(viewController: loggedInBuilder.loggedInViewController)
        }
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
        playersStore.remove(listener: self)
    }
}

extension RootViewController: PlayersStoreListener {
    func didUpdate(names: (String, String)) {
        updateChildViewController(names: names)
    }
}
