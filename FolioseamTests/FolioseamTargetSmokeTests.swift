import XCTest
@testable import Folioseam

/// Phase 0 smoke coverage: proves the unit-test target is wired to the app
/// target and can link against it. Replace as real suites land.
final class FolioseamTargetSmokeTests: XCTestCase {
    func test_givenTestBundle_whenReadingIdentifier_thenItMatchesTheConfiguredValue() {
        // Given
        let bundle = Bundle(for: FolioseamTargetSmokeTests.self)

        // When
        let identifier = bundle.infoDictionary?["CFBundleIdentifier"] as? String

        // Then
        XCTAssertEqual(identifier, "com.folioseam.bind.tests")
    }
}
