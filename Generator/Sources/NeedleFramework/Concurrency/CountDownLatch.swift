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

import Foundation

/// A concurrency utility class that allows coordination between threads. A count down latch
/// starts with an initial count. Threads can then decrement the count until it reaches zero,
/// at which point, the suspended waiting thread shall proceed.
public class CountDownLatch {

    /// The initial count of the latch.
    public let initialCount: Int

    /// Initializer.
    ///
    /// - parameter count: The initial count for the latch.
    public init(count: Int) {
        assert(count > 0, "CountDownLatch must have an initial count that is greater than 0.")

        initialCount = count
        countDownValue = count
        waitingCount = 0
    }

    /// Decrements the latch's count, resuming all awaiting threads if the count reaches zero.
    public func countDown() {
        // Use the serial queue to read and write to the count variable. This allows us to ensure
        // thread-safe access, while allowing this method to be invoked without blocking or any
        // contension.
        queue.async {
            guard self.countDownValue > 0 else {
                return
            }

            self.countDownValue -= 1

            if self.countDownValue == 0 {
                // Wake up all waiting invocations, not just threads. We cannot rely on the returned
                // value from dispatch_semaphore_signal since it returns true as long as any thread
                // is woken, momentarily. When the same thread invokes await multiple times, semaphore
                // signal method returns true even if it only unblocks the first await.
                while self.waitingCount > 0 {
                    self.semaphore.signal()
                    self.waitingCount -= 1
                }
            }
        }
    }

    /// Causes the current thread to suspend until the latch counts down to zero.
    ///
    /// - note: If the current count is already zero, this method returns immediately without suspending the current
    ///   thread.
    ///
    /// - parameter timeout: The optional timeout value in seconds. If the latch is not counted down to zero before the
    ///   timeout, this method returns false. If not defined, the current thread will wait forever until the latch is
    ///   counted down to zero.
    /// - returns: true if the latch is counted down to zero. false if the timeout occurred before the latch reaches
    ///   zero.
    public func await(timeout: TimeInterval? = nil) -> Bool {
        // Only use the queue to access count but not the semaphore wait, since we need to ensure
        // count is always accessed from the queue's thread. Do not wait on the semaphore inside
        // the queue, since the queue is serial, blocking the queue results in deadlock, since the
        // semaphore signal will also be blocked.
        let alreadyOpen: Bool = queue.sync {
            let alreadyOpen = self.countDownValue <= 0
            if !alreadyOpen {
                self.waitingCount += 1
            }
            return alreadyOpen
        }

        if alreadyOpen {
            return true
        } else {
            let deadline: DispatchTime
            if let timeout = timeout {
                deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(timeout * 1000))
            } else {
                deadline = .distantFuture
            }
            return self.semaphore.wait(timeout: deadline) == .success
        }
    }

    // MARK: - Private

    private let semaphore = DispatchSemaphore(value: 0)
    // Use a serial queue to read/write to the count, so we can avoid using locks. This allows
    // countDown method to be non-blocking and non-contending, while ensuring thread-safe access
    // of the count variable.
    private let queue = DispatchQueue(label: "CountDownLatch.executeQueue", qos: .userInteractive)

    private var countDownValue: Int
    private var waitingCount: Int
}
