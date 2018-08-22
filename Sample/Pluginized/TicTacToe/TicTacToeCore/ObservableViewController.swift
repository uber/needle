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

/// The lifecycle of a view controller.
enum ViewControllerLifecycle {
    case viewDidAppear
    case viewDidDisappear
    case `deinit`
}

/// A view controller whose lifecycle events can be observed via Rx.
class ObservableViewController: UIViewController {

    /// The lifecycle observable of this view controller.
    var lifecycle: Observable<ViewControllerLifecycle> {
        return lifecycleSubject.asObservable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        lifecycleSubject.onNext(.viewDidAppear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        lifecycleSubject.onNext(.viewDidDisappear)
    }

    // MARK: - Private

    private let lifecycleSubject = ReplaySubject<ViewControllerLifecycle>.create(bufferSize: 1)

    deinit {
        lifecycleSubject.onNext(.deinit)
    }
}
