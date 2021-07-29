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
import SwiftUI
import Combine
import XCTest

class RootViewTests: XCTestCase {

    private var loggedOutBuilder: LoggedOutBuilderMock!
    private var loggedInBuilder: LoggedInBuilderMock!
    private var rootViewModel: RootViewModelMock!
    private var rootView: RootView<RootViewModelMock>!

    override func setUp() {
        super.setUp()
        loggedOutBuilder = LoggedOutBuilderMock()
        loggedInBuilder = LoggedInBuilderMock()
    }

    func test_loggedOutView() {
        // Given
        rootViewModel = RootViewModelMock(state: .loggedOut)
        rootView = RootView(viewModel: rootViewModel, loggedOutBuilder: loggedOutBuilder, loggedInBuilder: loggedInBuilder)
        
        // When
        _ = rootView.body // force SwiftUI to render
        
        XCTAssertEqual(loggedInBuilder.loggedInViewCallCount, 0)
        XCTAssertEqual(loggedOutBuilder.loggedOutViewCallCount, 1)
    }
    
    func test_loggedInView() {
        // Given
        rootViewModel = RootViewModelMock(state: .loggedIn)
        rootView = RootView(viewModel: rootViewModel, loggedOutBuilder: loggedOutBuilder, loggedInBuilder: loggedInBuilder)
        
        // When
        _ = rootView.body // force SwiftUI to render
        
        XCTAssertEqual(loggedInBuilder.loggedInViewCallCount, 1)
        XCTAssertEqual(loggedOutBuilder.loggedOutViewCallCount, 0)
    }
}

class LoggedOutBuilderMock: LoggedOutBuilder {
    let view = EmptyView()

    var loggedOutViewCallCount = 0
    var loggedOutView: AnyView {
        loggedOutViewCallCount += 1
        return AnyView(view)
    }
}

class LoggedInBuilderMock: LoggedInBuilder {
    let view = EmptyView()

    var loggedInViewCallCount = 0
    var loggedInView: AnyView {
        loggedInViewCallCount += 1
        return AnyView(view)
    }
}

class RootViewModelMock: RootViewModelProtocol {
    var state: RootChildStates
    
    init(state: RootChildStates) {
        self.state = state
    }
}
