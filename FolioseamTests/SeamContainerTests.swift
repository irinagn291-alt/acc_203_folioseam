import XCTest
@testable import Folioseam

@MainActor
final class SeamContainerTests: XCTestCase {
    func test_givenContainer_whenMakeProjectsTwice_thenSameInstance() {
        let container = SeamContainer.preview()

        let first = container.makeProjectsViewModel()
        let second = container.makeProjectsViewModel()

        XCTAssertTrue(first === second)
    }
}
