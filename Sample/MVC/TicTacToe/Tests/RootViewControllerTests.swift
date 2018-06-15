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

@testable import TicTacToe
import RxSwift
import XCTest

class RootViewControllerTests: XCTestCase {

    private var playersStream: PlayersStreamMock!
    private var loggedOutBuilder: LoggedOutBuilderMock!
    private var loggedInBuilder: LoggedInBuilderMock!
    private var rootViewController: RootViewController!

    override func setUp() {
        super.setUp()

        playersStream = PlayersStreamMock()
        loggedOutBuilder = LoggedOutBuilderMock()
        loggedInBuilder = LoggedInBuilderMock()
        rootViewController = RootViewController(playersStream: playersStream, loggedOutBuilder: loggedOutBuilder, loggedInBuilder: loggedInBuilder)
    }

    func test_viewDidAppear_emitNoPlayers_withDuplicateEmissions_withDuplicateViewDidAppear_verifySinglePresentLoggedOut() {
        rootViewController.viewDidAppear(true)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 0)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 0)

        playersStream.subject.onNext(nil)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 1)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 0)

        playersStream.subject.onNext(nil)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 1)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 0)

        rootViewController.viewDidAppear(true)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 1)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 0)
    }

    func test_viewDidAppear_emitPlayers_withDuplicateEmissions_withDuplicateViewDidAppear_verifySinglePresentLoggedIn() {
        rootViewController.viewDidAppear(true)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 0)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 0)

        playersStream.subject.onNext(("blah", "haha"))

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 0)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 1)

        playersStream.subject.onNext(("blah", "haha"))

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 0)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 1)

        rootViewController.viewDidAppear(true)

        XCTAssertEqual(loggedOutBuilder.loggedOutViewControllerCallCount, 0)
        XCTAssertEqual(loggedInBuilder.loggedInViewControllerCallCount, 1)
    }
}

class PlayersStreamMock: PlayersStream {
    var names: Observable<(String, String)?> {
        return subject.asObservable()
    }

    let subject = PublishSubject<(String, String)?>()
}

class LoggedOutBuilderMock: LoggedOutBuilder {
    let viewController = UIViewController()

    var loggedOutViewControllerCallCount = 0
    var loggedOutViewController: UIViewController {
        loggedOutViewControllerCallCount += 1
        return viewController
    }
}

class LoggedInBuilderMock: LoggedInBuilder {
    let viewController = UIViewController()

    var loggedInViewControllerCallCount = 0
    var loggedInViewController: UIViewController {
        loggedInViewControllerCallCount += 1
        return viewController
    }
}
