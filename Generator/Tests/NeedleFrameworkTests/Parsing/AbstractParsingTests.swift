//
//  AbstractParsingTests.swift
//  NeedleFrameworkTests
//
//  Created by Yi Wang on 5/2/18.
//

import XCTest

/// Base class for all parsing related tests.
class AbstractParsingTests: XCTestCase {

    /// Retrieve the URL for a fixture file.
    ///
    /// - parameter file: The name of the file including extension.
    /// - returns: The fixture file URL.
    func fixtureUrl(for file: String) -> URL {
        return URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/\(file)")
    }
}
