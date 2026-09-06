import XCTest
final class JourneysTests:XCTestCase {
    func testOnboardingAndJournalPersistence() throws {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"];app.launch()
        for _ in 0..<3 {let button=app.buttons["onboarding-next"];XCTAssertTrue(button.waitForExistence(timeout:10));button.tap()}
        XCTAssertTrue(app.buttons["tab-journal"].waitForExistence(timeout:10));app.buttons["tab-journal"].tap()
        app.buttons["new-journal-entry"].tap()
        let field=app.descendants(matching:.any)["entry-notes"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText("A quiet afternoon by the water.")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()}
        app.swipeUp();app.buttons["save-entry"].tap()
        XCTAssertTrue(app.buttons["journal-entry"].waitForExistence(timeout:8))
        app.terminate();app.launchArguments=["--ui-testing"];app.launch();app.buttons["tab-journal"].tap()
        XCTAssertTrue(app.staticTexts["A quiet afternoon by the water."].waitForExistence(timeout:8))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="journal-persistence";shot.lifetime = .keepAlways;add(shot)
    }
}
