//
//  DirectoryScannerTests.swift
//  NeedleFrameworkTests
//
//  Created by Rudro Samanta on 4/30/18.
//

import XCTest
@testable import NeedleFramework

class DirectoryScannerTests: XCTestCase {
    let base = "/tmp/dirscantest/"

    override func setUp() {
        super.setUp()

        ["", "/junk", "/other"].map { URL(fileURLWithPath: base + $0) }.forEach {
            try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true, attributes: nil)
        }

        ["foo.swift", "fooskip.swift", "junk/bar.swift", "other/bar.swift", "other/barskip.swift", "noswift.cpp", "junk/ignore.txt"].map { base + $0 }.forEach {
            print($0)
            FileManager.default.createFile(atPath: $0, contents: "foo".data(using: .utf8), attributes: nil)
        }
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: base)

        super.tearDown()
    }

    func test_scanTestDirectory_verifyListOfFiles() {
        let scanner = DirectoryScanner(path: base, withoutSuffixes: nil)

        var all = [String]()
        scanner.scan { url in
            all.append(url.path)
        }
        let expected = ["/private/tmp/dirscantest/other/barskip.swift", "/private/tmp/dirscantest/other/bar.swift", "/private/tmp/dirscantest/junk/bar.swift", "/private/tmp/dirscantest/foo.swift", "/private/tmp/dirscantest/fooskip.swift"]
        XCTAssertTrue(all == expected)
    }

    func test_scanTestDirectoryWithSkip_verifyListOfFiles() {
        let scanner = DirectoryScanner(path: base, withoutSuffixes: ["skip"])

        var all = [String]()
        scanner.scan { url in
            all.append(url.path)
        }
        let expected = ["/private/tmp/dirscantest/other/bar.swift", "/private/tmp/dirscantest/junk/bar.swift", "/private/tmp/dirscantest/foo.swift"]
        XCTAssertTrue(all == expected)
    }
}
