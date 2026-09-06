import XCTest
/// A repeatable motion capture, using actual controls and a separate test journal.
final class ShowcaseTests:XCTestCase {
    func shot(_ name:String) {let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testWalkthroughAndMotion() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data","--measure-motion"];app.launch()
        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout:8));shot("01-underwater-arrival")
        Thread.sleep(forTimeInterval:1.2);app.buttons["onboarding-next"].tap();shot("02-meet-pip")
        Thread.sleep(forTimeInterval:1.2);app.buttons["onboarding-next"].tap();shot("03-privacy")
        app.buttons["onboarding-next"].tap();shot("04-atlas")
        app.buttons["Open Gantry Plaza"].tap();XCTAssertTrue(app.buttons["save-spot"].waitForExistence(timeout:5));app.buttons["save-spot"].tap();shot("05-water-notes")
        app.swipeUp();app.swipeDown();app.buttons["Done"].firstMatch.tap()
        app.buttons["tab-identify"].tap();shot("06-photo-arrival")
        app.buttons["photos-button"].tap();XCTAssertTrue(app.buttons["Collections"].waitForExistence(timeout:12));shot("07-native-photo-picker")
        app.coordinate(withNormalizedOffset:CGVector(dx:0.17,dy:0.44)).tap()
        let compare=app.buttons["compare-photo"];for _ in 0..<5 {if compare.isHittable {break};app.swipeUp()};XCTAssertTrue(compare.exists);compare.tap()
        let candidate=app.buttons["candidate-yellow-perch"];for _ in 0..<5 {if candidate.isHittable {break};app.swipeUp()};XCTAssertTrue(candidate.waitForExistence(timeout:15));candidate.tap();shot("08-species-reveal")
        let record=app.buttons["record-candidate"];for _ in 0..<5 {if record.isHittable {break};app.swipeUp()};record.tap()
        let notes=app.descendants(matching:.any)["entry-notes"].firstMatch;for _ in 0..<3 {if notes.isHittable {break};app.swipeUp()};notes.tap();notes.typeText("Showcase example. Photo from iNaturalist observation 150733403, CC BY. Not a personal catch.")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()}
        let save=app.buttons["save-entry"];for _ in 0..<4 {if save.isHittable {break};app.swipeUp()};save.tap()
        app.buttons["tab-journal"].tap();app.swipeUp();shot("09-field-journal")
        app.buttons["tab-pack"].tap();shot("10-preparation")
        for _ in 0..<4 {app.swipeUp();app.swipeDown()}
        app.buttons["tab-journal"].tap();app.swipeUp();shot("11-kept-moment")
    }
}
