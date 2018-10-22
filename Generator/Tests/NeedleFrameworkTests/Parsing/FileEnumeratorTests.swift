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

import XCTest
@testable import NeedleFramework

class FileEnumeratorTests: AbstractParserTests {

    func test_enumerate_withSourcesFile_verifyUrls() {
        let sourcesListUrl = fixtureUrl(for: "sources_list.txt")
        let enumerator = FileEnumerator()
        var urls = [String]()
        try! enumerator.enumerate(from: sourcesListUrl, withSourcesListFormat: nil) { (url: URL) in
            urls.append(url.absoluteString)
        }

        let expectedUrls = [
            "file:///Users/yiw/Uber/ios/vendor/box/Box/Box.swift",
            "file:///Users/yiw/Uber/ios/vendor/box/Box/BoxType.swift",
            "file:///Users/yiw/Uber/ios/vendor/box/Box/MutableBox.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/IntExtensions.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSON.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONDecodable.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONEncodable.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONEncodingDetector.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONLiteralConvertible.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONOptional.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONParser.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONParsing.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONSerializing.swift",
            "file:///Users/yiw/Uber/ios/vendor/freddy/Sources/JSONSubscripting.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/ConcurrentReadVariable.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/DispatchOperators.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/DispatchQueue.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/ReadWriteLock.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/RecursiveSyncLock.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/Sychronized.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Concurrency/SynchronizedDictionary.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Date/Date.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Errors/Asserts.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/DeviceExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/Enumerations.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/FoundationExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/Math.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/ObfuscationExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Extensions/SequenceExtensions.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/FileSystem/FileManaging.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/LogModelMetadata/LogModelMetadata.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Obfuscation/Obfuscation.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BuildType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BuildVersion.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Resources/BundleType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/Runtime/RunType.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/TestMocks/Manual/ManualProtocolMocks.swift",
            "file:///Users/yiw/Uber/ios/libraries/foundation/PresidioFoundation/PresidioFoundation/TestMocks/PresidioFoundationProtocolMocks.swift",
        ]

        XCTAssertEqual(urls, expectedUrls)
    }

    func test_enumerate_withEmptySourcesFile_verifyUrls() {
        let sourcesListUrl = fixtureUrl(for: "empty_lines_sources_list.txt")
        let enumerator = FileEnumerator()
        var urls = [String]()
        try! enumerator.enumerate(from: sourcesListUrl, withSourcesListFormat: nil) { (url: URL) in
            urls.append(url.absoluteString)
        }

        XCTAssertTrue(urls.isEmpty)
    }

    func test_enumerate_withNonexistentSourcesFile_verifyUrls() {
        let sourcesListUrl = fixtureUrl(for: "doesNotExist.txt")
        let enumerator = FileEnumerator()
        do {
            try enumerator.enumerate(from: sourcesListUrl, withSourcesListFormat: nil) { _ in }
            XCTFail()
        } catch {
            switch error {
            case FileEnumerationError.failedToReadSourcesList(let url, _):
                XCTAssertEqual(url, sourcesListUrl)
            default:
                XCTFail()
            }
        }
    }

    func test_enumerate_withMinimallyEscapedFormat_verifyUrls() {
        let sourcesListUrl = fixtureUrl(for: "sources_list_minescaped.txt")
        let enumerator = FileEnumerator()
        var urls = [String]()
        try! enumerator.enumerate(from: sourcesListUrl, withSourcesListFormat: "minescaping") { (url: URL) in
            urls.append(url.absoluteString)
        }

        let expectedUrls = [
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/AppStartup/LaunchSteps/NetworkingStep.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/AppStartup/LaunchSteps/RootRIBStep.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/AppStartup/LaunchSteps/StacktraceGenerationStep.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/AppStartup/LaunchSteps/StartupReasonReporterStep.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/AppStartup/LaunchSteps/StorageStep.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsBuilder.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsHistogramContainerView.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsInteractor.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsRouter.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsSummaryViewController.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/DeliveryRatingsViewController.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/DeliveriesRatingLateTripBuilder.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/DeliveriesRatingLateTripInteractor.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/DeliveriesRatingLateTripRouter.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/DeliveriesRatingLateTripViewController.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/Views/DeliveriesRatingLateTripDescriptionCell.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/PluginFeatures/ProfileRatings/ProfileRatings/Rides%20&%20Deliveries/Deliveries/Late%20Delivery/Views/DeliveriesRatingLateTripItemCell.swift",
            "file:///Users/yiw/Uber/ios/libraries/common/ContactPicker/ContactPicker/View%20Models/ContactViewModel.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/AccountBuilder.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/AccountInteractor.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/AccountRouter.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/AccountViewController.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/Component/AccountComponent+AccountNonCore.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/Component/AccountComponent+VehicleSelection.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/Views/AccountItemCell.swift",
            "file:///Users/yiw/Uber/ios/apps/carbon/Driver/DriverCore/DriverCore/Account/Views/AccountSignOutCell.swift",
            ]

        XCTAssertEqual(urls, expectedUrls)
    }
}
