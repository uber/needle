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

import Combine
import Foundation

final class ReplaySubject<Output, Failure: Error>: Subject {
    private var buffer = [Output]()
    private let bufferSize: Int
    private let lock = NSRecursiveLock()
    private var subscriptions = [ReplaySubjectSubscription<Output, Failure>]()
    private var completion: Subscribers.Completion<Failure>?

    init(_ bufferSize: Int = 0) {
        self.bufferSize = bufferSize
    }
}

extension ReplaySubject {
    
    func receive<Downstream: Subscriber>(subscriber: Downstream) where Downstream.Failure == Failure, Downstream.Input == Output {
        lock.lock(); defer { lock.unlock() }
        let subscription = ReplaySubjectSubscription<Output, Failure>(downstream: AnySubscriber(subscriber))
        subscriber.receive(subscription: subscription)
        subscriptions.append(subscription)
        subscription.replay(buffer, completion: completion)
    }
}

extension ReplaySubject {

    /// Establishes demand for a new upstream subscriptions
    func send(subscription: Subscription) {
        lock.lock(); defer { lock.unlock() }
        subscription.request(.unlimited)
    }

    /// Sends a value to the subscriber.
    func send(_ value: Output) {
        lock.lock(); defer { lock.unlock() }
        buffer.append(value)
        buffer = buffer.suffix(bufferSize)
        subscriptions.forEach { $0.receive(value) }
    }

    /// Sends a completion event to the subscriber.
    func send(completion: Subscribers.Completion<Failure>) {
        lock.lock(); defer { lock.unlock() }
        self.completion = completion
        subscriptions.forEach { subscription in subscription.receive(completion: completion) }
    }
}

final class ReplaySubjectSubscription<Output, Failure: Error>: Subscription {
    private let downstream: AnySubscriber<Output, Failure>
    private var isCompleted = false
    private var demand: Subscribers.Demand = .none

    init(downstream: AnySubscriber<Output, Failure>) {
        self.downstream = downstream
    }

    func request(_ newDemand: Subscribers.Demand) {
        demand += newDemand
    }

    func cancel() {
        isCompleted = true
    }

    func receive(_ value: Output) {
        guard !isCompleted, demand > 0 else { return }

        demand += downstream.receive(value)
        demand -= 1
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        guard !isCompleted else { return }
        isCompleted = true
        downstream.receive(completion: completion)
    }

    func replay(_ values: [Output], completion: Subscribers.Completion<Failure>?) {
        guard !isCompleted else { return }
        values.forEach { value in receive(value) }
        if let completion = completion { receive(completion: completion) }
    }
}
