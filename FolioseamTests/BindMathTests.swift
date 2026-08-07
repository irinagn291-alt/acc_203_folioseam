import XCTest
@testable import Folioseam

final class BindMathTests: XCTestCase {
    func test_stageProgress_whenHalfDone_thenReturnsHalf() {
        // Given / When
        let value = BindMath.stageProgress(doneStages: 3, totalStages: 6)
        // Then
        XCTAssertEqual(value, 0.5, accuracy: 0.0001)
    }

    func test_sectionProgress_whenEmpty_thenZero() {
        XCTAssertEqual(BindMath.sectionProgress(sewnSections: 0, totalSections: 0), 0)
    }

    func test_projectProgress_weightsStageAndSection() {
        let value = BindMath.projectProgress(stageProgress: 1, sectionProgress: 0, hasSections: true)
        XCTAssertEqual(value, 0.6, accuracy: 0.0001)
    }

    func test_projectProgress_withoutSections_usesStageOnly() {
        let value = BindMath.projectProgress(stageProgress: 0.4, sectionProgress: 1, hasSections: false)
        XCTAssertEqual(value, 0.4, accuracy: 0.0001)
    }

    func test_conditionDelta_whenBothPresent() {
        XCTAssertEqual(BindMath.conditionDelta(before: 40, after: 70), 30)
        XCTAssertNil(BindMath.conditionDelta(before: 40, after: nil))
    }

    func test_materialSpend_sumsCents() {
        XCTAssertEqual(BindMath.materialSpend(costCents: [150, 50]), 2.0, accuracy: 0.0001)
    }
}
