import XCTest

/// Smoke test: app launches successfully and reaches the tab bar.
///
/// `runsForEachTargetApplicationUIConfiguration` is intentionally omitted
/// (defaults to false) to avoid running this test once per appearance/locale
/// combination, which causes duplicate runs and inflates test time.
final class SurVibeUITestsLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launch()

        // Verify the app reaches the tab bar (not stuck on onboarding or a crash screen)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5),
                      "Tab bar should appear within 5s of launch")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
