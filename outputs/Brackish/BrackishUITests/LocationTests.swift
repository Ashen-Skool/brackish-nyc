import XCTest
/// Run separately with simctl privacy revoke/grant as documented in verify-location.sh.
final class LocationTests:XCTestCase {
    func start()->XCUIApplication {let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"];app.launch();for _ in 0..<3 {let b=app.buttons["onboarding-next"];XCTAssertTrue(b.waitForExistence(timeout:8));b.tap()};return app}
    func testDeniedLocationAndManualArea() {
        let app=start();app.buttons["Near me"].tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH 'Location is unavailable'")).firstMatch.waitForExistence(timeout:15))
        app.buttons["atlas-area"].tap();app.buttons["Queens"].tap()
        XCTAssertTrue(app.buttons["spot-gantry"].waitForExistence(timeout:5))
        let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name="location-denied-manual-area";a.lifetime = .keepAlways;add(a)
    }
    func testGrantedLocationDistances() {
        let app=start();app.buttons["Near me"].tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH 'Sorted by straight-line'")).firstMatch.waitForExistence(timeout:15))
        XCTAssertTrue(app.buttons["spot-gantry"].exists)
        let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name="location-distance-order";a.lifetime = .keepAlways;add(a)
    }
}
