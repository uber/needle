import XCTest
@testable import NeedleFrameworkTests

XCTMain([
    testCase(AtomicIntTests.allTests),
    testCase(CountDownLatchTests.allTests),
])
