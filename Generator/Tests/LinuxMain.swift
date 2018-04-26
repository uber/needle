import XCTest
@testable import NeedleFrameworkTests

XCTMain([
    testCase(AtomicIntTests.allTests),
    testCase(AtomicReferenceTests.allTests),
    testCase(CountDownLatchTests.allTests),
])
