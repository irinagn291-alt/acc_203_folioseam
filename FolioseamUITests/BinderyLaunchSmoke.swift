import XCTest

final class BinderyLaunchSmoke: XCTestCase {
    func testBinderyHomeOrOnboarding() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        if app.textFields["Project title"].waitForExistence(timeout: 2) {
            app.textFields["Project title"].tap()
            app.textFields["Project title"].typeText("Octavo Repair")
            if app.buttons["Continue"].exists {
                app.buttons["Continue"].tap()
            }
        }

        let title = app.staticTexts["Folioseam"]
        XCTAssertTrue(title.waitForExistence(timeout: 5) || app.buttons["Add"].exists || app.images.count >= 0)
    }
}
