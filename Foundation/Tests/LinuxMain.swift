import XCTest
@testable import NeedleFrameworkTests

XCTMain([
    testCase(ComponentTests.allTests),
    testCase(DependencyProviderRegistryTests.allTests),
])
