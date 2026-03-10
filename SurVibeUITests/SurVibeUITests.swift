import XCTest

/// D1: App launches, TabView shows 4 tabs.
/// D7: VoiceOver labels on all tabs.
final class SurVibeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesWithFourTabs() throws {
        let app = XCUIApplication()
        app.launch()

        // D1: Verify 4 tabs are visible
        XCTAssertTrue(app.tabBars.buttons["Learn"].exists, "Learn tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Practice"].exists, "Practice tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Songs"].exists, "Songs tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists, "Profile tab should exist")
    }

    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate through all tabs
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.navigationBars["Pitch Detection"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Songs"].tap()
        XCTAssertTrue(app.navigationBars["Songs"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.navigationBars["Learn"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
